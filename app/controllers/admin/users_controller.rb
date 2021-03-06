class Admin::UsersController < ApplicationController
  load_and_authorize_resource
  skip_load_resource only: :edit
  before_action :load_user, only: :edit
  before_action :load_data, except: [:index, :show, :destroy]
  before_action :load_breadcrumb_edit, only: [:edit, :update]
  before_action :load_breadcrumb_new, only: [:new, :create]
  before_action :quick_create_profile, except: [:index, :destroy, :show]

  def index
    respond_to do |format|
      format.html {add_breadcrumb_index "users"}
      format.json {
        render json: UsersDatatable.new(view_context, @namespace)
      }
    end
  end

  def new
    build_profile
  end

  def create
    if @user.save
      UserSendMailService.new(@user).send_welcome_mail
      flash[:success] = flash_message "created"

      if params[:commit].present?
        redirect_to admin_users_path
      else
        redirect_to new_admin_user_path
      end
    else
      render :new
    end
  end

  def edit
    build_profile unless @user.profile
  end

  def update
    if params[:nodeDataArray]
      update_user_charts params[:nodeDataArray]
    else
      if @user.update_attributes user_params
        sign_in(@user, bypass: true) if current_user? @user
        flash[:success] = flash_message "updated"
        redirect_to admin_users_path
      else
        render :edit
      end
    end
  end

  def destroy
    if @user.destroy
      flash[:success] = flash_message "deleted"
    else
      flash[:alert] = flash_message "not_deleted"
    end
    redirect_to admin_users_path
  end

  def show
    add_breadcrumb_path "users"

    @activities = PublicActivity::Activity.includes(:owner, :trackable)
      .user_activities(@user.id).recent.limit(20).decorate
    @user_courses = @user.user_courses
    @finished_courses = @user_courses.course_finished
    @inprogress_course = @user_courses.course_progress.last

    if @inprogress_course
      @user_subjects = @inprogress_course.user_subjects
        .includes(course_subject: :subject).order_by_course_subject
    end

    @note = Note.new
    @notes = Note.load_notes @user, current_user

    add_breadcrumb @user.name
  end

  private

  def update_user_charts params
    params.each do |_index, user_param|
      user = User.find_by id: user_param[:key]
      user.update_attributes parent_path: user_param[:parent]
    end
  end

  def user_params
    params.require(:user).permit User::ATTRIBUTES_PARAMS
  end

  def load_data
    datas = [Role, University, ProgrammingLanguage, Status, UserType, Location]
    datas.each do |data|
      instance_variable_set "@#{data.table_name}", data.all
    end
    @trainers = User.trainers.includes(:profile)
  end

  def load_breadcrumb_edit
    add_breadcrumb_path "users"
    add_breadcrumb @user.name, admin_user_path(@user)
    add_breadcrumb_edit "users"
  end

  def load_breadcrumb_new
    add_breadcrumb_path "users"
    add_breadcrumb_new "users"
  end

  def build_profile
    @user.build_profile
  end

  def quick_create_profile
    @location = Location.new
    @user_type = UserType.new
    @university = University.new
    @managers = User.not_trainees
  end

  def load_user
    @user = User.includes(:profile).find_by_id params[:id]
    if @user.nil?
      flash[:alert] = flash_message "not_find"
      redirect_to admin_users_path
    end
  end
end
