class CommentsController < ApplicationController
  before_filter :load_comment, :only => [:edit, :update, :show, :destroy]
  before_filter :load_target, :only => [:create]
  before_filter :load_orginal_controller, :only => [:create]
  before_filter :set_page_title

  cache_sweeper :task_list_panel_sweeper, :only => [:create]

  def create
    if params.has_key?(:project_id)
      @comment  = @current_project.new_comment(current_user,@target,params[:comment])
      @comments = @current_project.comments
    else
      @comment = current_user.new_comment(current_user,@target,params[:comment])
    end
    if @comment.save
      @comment.save_uploads(params)
      @comment.save_google_docs(params,current_user,session)
    end

    @target = @comment.target

    # Evaluate target
    case @target
    when Conversation
      @conversation = @comment.target
      redirect_path = project_conversation_path(@current_project, @conversation)
    when TaskList
      @task_list = @comment.target
      redirect_path = project_task_list_path(@current_project, @task_list)
    when Task
      @comment.reload
      @task = @comment.target
      @target = @task
      @task_list = @task.task_list
      @new_comment = @current_project.comments.new
      @new_comment.target = @task
      @new_comment.status = @task.status
      redirect_path = project_task_list_task_path(@current_project, @task_list, @task)
    else
      redirect_path = project_path(@target || @current_project)
    end

    respond_to do |f|
      f.html { redirect_to redirect_path }
      f.m    { redirect_to redirect_path }
      f.js
    end
  end

  def show
    respond_to{|f|f.js}
  end

  def edit
    respond_to{|f|f.js}
  end

  def update
    if @comment.update_attributes(params[:comment])
      @comment.save_uploads(params)
      @comment.save_google_docs(params,current_user,session)
    end
    respond_to{|f|f.js}
  end

  def destroy
    @comment.destroy
  end

  def preview
    if params.has_key?(:project_id)
      @comment  = @current_project.new_comment(current_user,@target,params[:comment])
    else
      @comment = current_user.new_comment(current_user,@target,params[:comment])
    end

    @comment.send(:format_attributes)
    render :text => @comment.body_html
  end

  private

    def load_orginal_controller
      @original_controller = params[:original_controller]
    end

    def load_comment
      @comment = Comment.find(params[:id])
    end

    def load_target
      if params.has_key?(:project_id)
        @target = assign_project_target
      else
        @target = User.find(params[:user_id])
      end
    end

    def assign_project_target
      if params.has_key?(:task_id)
        t = Task.find(params[:task_id])
        t.previous_status = t.status
        t.previous_assigned_id = t.assigned_id
        t.status = params[:comment][:status]
        if params[:comment][:target_attributes]
          t.assigned_id = params[:comment][:target_attributes][:assigned_id]
        end
        #if t.archived? && [Task::STATUSES[:new],Task::STATUSES[:open],Task::STATUSES[:hold]].include?(t.status)
        #  t.archived = false
        # end
        t
      elsif params.has_key?(:task_list_id)
        TaskList.find(params[:task_list_id])
      elsif params.has_key?(:conversation_id)
        Conversation.find(params[:conversation_id])
      else
        @current_project
      end
    end
end
