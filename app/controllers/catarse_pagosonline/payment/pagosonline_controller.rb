# encoding: utf-8

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
        reference: "sumame-proyect-#{contribution.project.id}-contribution-#{contribution.id}-user-#{current_user.id}",
        description: "#{contribution.value} donation to #{contribution.project.name}",
        amount: contribution.value,
        currency: 'COP',
        response_url: payment_success_pagosonline_url(id: contribution.id),
        confirmation_url: payment_notifications_pagosonline_url(id: contribution.id),
        language: 'es'
      })
      @form = response.form do |f|
        "<input type=\"submit\" value=\"APOYA A TRAVÉS DE PAGOS ON LINE\" class=\"btn btn-info btn-large\"/>"
      end
    end

    def success
      #contribution = current_user.backs.find params[:id]
      contribution = ::Contribution.find(params[:id])
      begin
        # response = @@gateway.Response.new(params)
        response = Pagosonline::Response.new(@@gateway, params)
        # puts "*****#{response.inspect}***"
        if response.valid?
          contribution.update_attribute :payment_method, 'PagosOnline'
          contribution.update_attribute :payment_token, response.transaccion_id

          proccess!(contribution, response)

          unless response.success?
            pagosonline_error response.answer_message
          else
            pagosonline_flash_success  
          end
          

          redirect_to main_app.project_contribution_path(project_id: contribution.project.id, id: contribution.id)
        else
          puts "************ NO ES VALIDA LA FIRMA"
          datos = [response.client.key,response.client.account_id, response.reference,("%.2f" % response.amount), response.currency, response.state_code].join("~")
        signa = Digest::MD5.hexdigest(datos)


        puts "*******valores del response: #{params[:firma].upcase} debe ser igual a #{signa.upcase} que sale de firmar #{datos}"
          pagosonline_flash_error
          return redirect_to main_app.new_project_contribution_path(contribution.project)  
        end
      rescue Exception => e
        # ::Airbrake.notify({ :error_class => "PagosOnline Error", :error_message => "PagosOnline Error: #{e.inspect}", :parameters => params}) rescue nil
        Rails.logger.info "--success error-----> #{e.inspect}"
        pagosonline_flash_error
        return redirect_to main_app.new_project_contribution_path(contribution.project)
      end
    end

    def notifications
      # contribution = current_user.backs.find params[:id]
      contribution = ::Contribution.find(params[:id])
      response = Pagosonline::Response.new(@@gateway, params)
      # response = @@gateway.Response.new(params)
       puts "88888 VAMOS A ENTRAR A VALIDAR esta condicion(#{response.valid?})"
      if response.valid?
        puts "******* VAMOS A VALIDAR :)"
        proccess!(contribution, response)
        render status: 200, nothing: true
      else
        puts "************ NO ES VALIDA LA FIRMA"
        datos = [response.client.key,response.client.account_id, response.reference,("%.2f" % response.amount), response.currency, response.state_code].join("~")
        signa = Digest::MD5.hexdigest(datos)


        puts "*******valores del response: #{params[:firma].upcase} debe ser igual a #{signa.upcase} que sale de firmar #{datos}"

        render status: 404, nothing: true
      end
    rescue Exception => e
      # ::Airbrake.notify({ :error_class => "PagosOnline Notification Error", :error_message => "PagosOnline Notification Error: #{e.inspect}", :parameters => params}) rescue nil
      Rails.logger.info "--notifications error-----> #{e.inspect}"
      render status: 404, nothing: true
    end

    protected

    def proccess!(contribution, response)
      notification = contribution.payment_notifications.new({
        extra_data: response.params
      })

      if response.success?
        puts "***********ES UN success"
        contribution.confirm!  
      elsif response.failure?
        puts "******** ES UN FAILURE"
        contribution.pendent!
      end
    end

    def pagosonline_error(error_message)
      flash[:failure] = t('pagosonline_error', scope: SCOPE) << error_message
    end
    
    def pagosonline_flash_error
      flash[:failure] = t('pagosonline_error', scope: SCOPE)
    end

    def pagosonline_flash_success
      flash[:success] = t('success', scope: SCOPE)
    end

    def setup_gateway
      if ::Configuration[:pagosonline_key] and ::Configuration[:pagosonline_account_id] and ::Configuration[:pagosonline_test]
        @@gateway ||= Pagosonline::Client.new({
          account_id: ::Configuration[:pagosonline_account_id],
          key: ::Configuration[:pagosonline_key],
          test: ::Configuration[:pagosonline_test].to_i
        })
      else
        raise "[PagosOnline] pagosonline_test and pagosonline_key and pagosonline_account_id are required to make requests to PagosOnline"
      end
    end

  end
end