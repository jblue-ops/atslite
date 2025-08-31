# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_sign_up_params, only: [:create]
    before_action :configure_account_update_params, only: [:update]

    # GET /resource/sign_up
    def new
      build_resource({})
      @organizations = Organization.active.limit(100) # For existing organizations
      @resource.build_organization if @resource.organization.blank?
      respond_with resource
    end

    # POST /resource
    def create
      build_resource(sign_up_params)

      # Handle organization creation or selection
      if params[:user][:create_organization] == "true"
        @organization = Organization.new(organization_params)
        if @organization.save
          resource.organization = @organization
          resource.role = "admin" # First user is always admin
        else
          resource.errors.add(:organization, @organization.errors.full_messages.join(", "))
          @organizations = Organization.active.limit(100)
          return render :new, status: :unprocessable_entity
        end
      else
        @organization = Organization.find(params[:user][:organization_id]) if params[:user][:organization_id].present?
        resource.organization = @organization
        resource.role = "recruiter" # Default role for joining existing org
      end

      resource.save
      yield resource if block_given?

      if resource.persisted?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_up!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        @organizations = Organization.active.limit(100)
        respond_with resource
      end
    end

    protected

    # If you have extra params to permit, append them to the sanitizer.
    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: [
                                          :first_name, :last_name, :phone, :role, :organization_id, :create_organization,
                                          { organization_attributes: %i[name website industry size_category description] }
                                        ])
    end

    # If you have extra params to permit, append them to the sanitizer.
    def configure_account_update_params
      devise_parameter_sanitizer.permit(:account_update, keys: %i[
                                          first_name last_name phone time_zone
                                        ])
    end

    private

    def organization_params
      params.require(:user).require(:organization_attributes).permit(
        :name, :website, :industry, :size_category, :description
      )
    end

    def after_sign_up_path_for(resource)
      if resource.admin?
        "/admin/dashboard" # Will be replaced with actual route
      else
        "/dashboard" # Will be replaced with actual route
      end
    end

    def after_inactive_sign_up_path_for(_resource)
      root_path
    end
  end
end
