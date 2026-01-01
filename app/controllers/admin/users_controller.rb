# frozen_string_literal: true

module Admin
  class UsersController < ApplicationController
    before_action :set_user, only: [:show, :edit, :update, :destroy]
    before_action :authorize_user_management

    def index
      @users = User.order(created_at: :desc)
      @users = @users.where(role: params[:role]) if params[:role].present?
    end

    def show
      # User details page
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)

      if @user.save
        redirect_to admin_user_path(@user), notice: "Usuario creado exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      # Edit user form
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "Usuario actualizado exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      email = @user.email
      @user.destroy
      redirect_to admin_users_path, notice: "Usuario #{email} eliminado exitosamente."
    end

    private

    def set_user
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_users_path, alert: "Usuario no encontrado."
    end

    def authorize_user_management
      authorize nil, policy_class: Admin::UsersPolicy
    end

    def user_params
      params.require(:user).permit(:email, :full_name, :password, :password_confirmation, :role, :phone_number)
    end
  end
end
