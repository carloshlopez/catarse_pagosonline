module CatarsePagosonline::Payment
  class PagosonlineController < ApplicationController
    skip_before_filter :verify_authenticity_token, :only => [:notifications]
    skip_before_filter :detect_locale, :only => [:notifications]
    skip_before_filter :set_locale, :only => [:notifications]
    skip_before_filter :force_http
    
    before_filter :setup_gateway
    
    SCOPE = "projects.contributions.checkout"

    layout :false

    def review
      # contribution = current_user.backs.not_confirmed.find params[:id]
      contribution = ::Contribution.find(params[:id])
      # Just to render the review form
      response = @@gateway.payment({
        reference: "sumame;proyect:#{contribution.project.id};contribution:#{contribution.id};user:#{current_user.id}",
        description: "#{contribution.value} donation to #{contribution.project.name}",
        amount: contribution.value,
        currency: 'COP',
        response_url: payment_success_pagosonline_url(id: contribution.id),
        confirmation_url: payment_notifications_pagosonline_url(id: contribution.id),
        language: 'es'
      })
      @form = response.form do |f|
        "<input type=\"submit\" value=\"Pagar\" />"
      end
    end

    def success
      #contribution = current_user.backs.find params[:id]
      contribution = ::Contribution.find(params[:id])
      begin
        response = @@gateway.Response.new(params)
        if response.valid?
          contribution.update_attribute :payment_method, 'PagosOnline'
          contribution.update_attribute :payment_token, response.transaccion_id

          proccess!(contribution, response)

          pagosonline_flash_success
          redirect_to main_app.project_contribution_path(project_id: contribution.project.id, id: contribution.id)
        else
          pagosonline_flash_error
          return redirect_to main_app.new_project_contribution_path(contribution.project)  
        end
      rescue Exception => e
        ::Airbrake.notify({ :error_class => "PagosOnline Error", :error_message => "PagosOnline Error: #{e.inspect}", :parameters => params}) rescue nil
        Rails.logger.info "-----> #{e.inspect}"
        pagosonline_flash_error
        return redirect_to main_app.new_project_contribution_path(contribution.project)
      end
    end

    def notifications
      contribution = current_user.backs.find params[:id]
      response = @@gateway.Response.new(params)
      if response.valid?
        proccess!(contribution, response)
        render status: 200, nothing: true
      else
        render status: 404, nothing: true
      end
    rescue Exception => e
      ::Airbrake.notify({ :error_class => "PagosOnline Notification Error", :error_message => "PagosOnline Notification Error: #{e.inspect}", :parameters => params}) rescue nil
      Rails.logger.info "-----> #{e.inspect}"
      render status: 404, nothing: true
    end

    protected

    def proccess!(contribution, response)
      notification = contribution.payment_notifications.new({
        extra_data: response.params
      })

      if response.success?
        contribution.confirm!  
      elsif response.failure?
        contribution.pendent!
      end
    end

    def pagosonline_flash_error
      flash[:failure] = t('pagosonline_error', scope: SCOPE)
    end

    def pagosonline_flash_success
      flash[:success] = t('success', scope: SCOPE)
    end

    def setup_gateway
      if ::Configuration[:pagosonline_username] and ::Configuration[:pagosonline_key] and ::Configuration[:pagosonline_merchant_id] and ::Configuration[:pagosonline_account_id]
        @@gateway ||= Pagosonline::Client.new({
          merchant_id: ::Configuration[:pagosonline_merchant_id],
          account_id: ::Configuration[:pagosonline_account_id],
          login: ::Configuration[:pagosonline_username],
          key: ::Configuration[:pagosonline_key],
          test: true
        })
      else
        raise "[PagosOnline] pagosonline_username, pagosonline_key, pagosonline_merchant_id and pagosonline_account_id are required to make requests to PagosOnline"
      end
    end

  end
end