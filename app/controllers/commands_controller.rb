class CommandsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_command, only: [:show, :edit, :update, :destroy]

  # GET /commands
  # GET /commands.json
  def index
    init(false,false)
    
  end

# gestion des affichage par dateFinal
  def front_date (list)
    @listDate = []
    tmplist=list.find_all { |e| e and e.dateFinal }
    list=tmplist.uniq.sort_by { |obj| obj.dateFinal }
    if !list.empty?
      @firstDate = list.first.dateFinal
      list.each do |element|
        if @firstDate > element.dateFinal
          @firstDate = element.dateFinal
        end
      end

      dateBefore = list.first.dateFinal
      @listDate.push(dateBefore)
      list.each do |commande|
        if commande.dateFinal != dateBefore
          @listDate.each do |tmpdate|
            if commande.dateFinal == tmpdate
              break
            end
          end
          dateBefore=commande.dateFinal
          @listDate.push(commande.dateFinal)
        end
      end
    end
  end

  def historique
    @current_user=current_user
    @prixTotal=0
    value=params[:begin]
    if !current_user.admin?
      if value != nil
        left, right = value.split("-").map(&:to_i)
        d = DateTime.new(left,right).beginning_of_month
        @commands=@current_user.commands.where(dateFinal: d..d.next_month)
      else
        actual_date=Date.today.beginning_of_month
        @commands=[]
      end
    else
      if value != nil
        left, right = value.split("-").map(&:to_i)
        d = DateTime.new(left,right).beginning_of_month
        @commands=Command.where(dateFinal: d..d.next_month)
      else
        @commands=[]
      end
    end
    if @commands == nil
      @commands=[]
    end
    front_date(@commands)
    @commands.each do |commande|
      @prixTotal += (commande.price * commande.unit)
    end
    tmpcommands=@commands.find_all { |e| e and e.timeFinalFrom }
    @commands=tmpcommands.uniq.sort_by { |obj| obj.timeFinalFrom }
  end

  def init (condition1, condition2)


    @prixTotal=0
    @commands = []
    @tmpcommands = Command.all.order(params[:dateFinal])


    # gestion des affichages des commandes par trie d'admin et d'état

    @tmpcommands.each do |command|
      if (command.statewait == condition1 && command.statedone == condition2)
        if !current_user.admin?
          if command.user_id == current_user.id
            @commands.push(command)
          end
        else
          @commands.push(command)
        end
      end
    end
    # Affichage du total du prix
    @commands.each do |commande|
      @prixTotal += (commande.price * commande.unit)
    end
    front_date(@commands)
    tmpcommands=@commands.find_all { |e| e and e.timeFinalFrom }
    @commands=tmpcommands.uniq.sort_by { |obj| obj.timeFinalFrom }
  end
  def today
    @prixTotal=0


    @commands = []
    @commandes = Command.all.order(params[:dateFinal])


    #trie des commandes par clients
    date=Date.today

    @commandes.each do |command|
      if( command.dateFinal==date)
          if !current_user.admin?
            if command.user_id == current_user.id
              @commands.push(command)
            end
          else
            @commands.push(command)
          end
      end
    end
    #créations du prix total sur les pages
    @commands.each do |commande|
      @prixTotal += commande.price * commande.unit
    end
    #création de liste de date pour l'affichage et le tri des commandes
    front_date(@commands)
    tmpcommands=@commands.find_all { |e| e and e.timeFinalFrom }
    @commands=tmpcommands.uniq.sort_by { |obj| obj.timeFinalFrom }
  end

  def week
    @prixTotal=0


    @commands = []
    @commandes = Command.all.order(params[:dateFinal])

    dateB=Date.today.beginning_of_week(:monday)
    @test1=dateB

    dateE=Date.today.end_of_week(:monday)
    @test2=dateE
    #trie des commandes par clients
    @commandes.each do |command|
      if (command.dateFinal <= dateE && command.dateFinal >= dateB)
          if !current_user.admin?
            if command.user_id == current_user.id
              @commands.push(command)
            end
          else
            @commands.push(command)
          end

      end
    end
    #créations du prix total sur les pages
    @commands.each do |commande|
      @prixTotal += commande.price * commande.unit
    end
    #création de liste de date pour l'affichage et le tri des commandes
    front_date(@commands)
    tmpcommands=@commands.find_all { |e| e and e.timeFinalFrom }
    @commands=tmpcommands.uniq.sort_by { |obj| obj.timeFinalFrom }
  end

  def during
    @prixTotal=0


    @commands = []
    @commandes = Command.all.order(params[:dateFinal])


    #trie des commandes par clients
    @commandes.each do |command|
      if (command.statewait == true || command.statedone == true)
        if !current_user.admin?
          if command.user_id == current_user.id
            @commands.push(command)
          end
        else
          @commands.push(command)
        end
      end
    end
    #créations du prix total sur les pages
    @commands.each do |commande|
      @prixTotal += commande.price * commande.unit
    end
    #création de liste de date pour l'affichage et le tri des commandes
    front_date(@commands)
    tmpcommands=@commands.find_all { |e| e and e.timeFinalFrom }
    @commands=tmpcommands.uniq.sort_by { |obj| obj.timeFinalFrom }
  end

  def export

    commands = Command.all
    commands.each do |c|
      if !current_user.admin?
        commands = Command.all.where({usercommand: current_user.username})
      end
    end
    if !commands.nil?
      respond_to do |format|
        format.html
        format.csv { send_data commands.to_csv }
      end
    end
  end


  # GET /commands/1
  # GET /commands/1.json
  def show
  end

  # GET /commands/new
  def new
    @user=current_user
    @command = current_user.commands.new
  end

  # GET /commands/1/edit
  def edit
  end

  # POST /commands
  # POST /commands.json

  def create

    @user=current_user
    @command = @user.commands.new(command_params)
    @command.statewait=false
    @command.statedone=false

    # choix du prix de la commande
    if @command.zipcode.present?
      if (@command.zipcode > 75000) && (@command.zipcode < 75021)
        @command.price = current_user.price1
      else
        @command.price = current_user.price2
      end
    end
    date_actuel = DateTime.now

    if @command.timeEnterFrom == nil
      @command.timeEnterFrom = date_actuel.change(hour: 11, min: 0)
    end
    if @command.timeEnterTo == nil
      @command.timeEnterTo = date_actuel.change(hour: 24, min: 0)
    end

    #initialisation de la date normal selectionner
    @command.usercommand = current_user.username
    @command.dateFinal = @command.dateEnter
    @command.timeFinalFrom = @command.timeEnterFrom
    @command.timeFinalTo = @command.timeEnterTo

    # cas d'inversion de des horaires
    if @command.dateEnter?
      if @command.timeFinalFrom > @command.timeFinalTo && @command.dateEnter?
        tmpdate=@command.dateFinal
        tmpdate=@command.timeFinalFrom
        @command.timeFinalFrom = @command.timeFinalTo
        @command.timeFinalTo = tmpdate
      end
    end


    respond_to do |format|
      if @command.save
        #CommandNotifierMailer.send_signup_email(@user,@command).deliver
        format.html { redirect_to commands_url, notice: 'La commande a été créée.' }
      else
        format.html { render :new }
        format.json { render json: @command.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /commands/1
  # PATCH/PUT /commands/1.json
  def update
    if @command.dateModif != nil
        @command.dateFinal = @command.dateModif
    end
    if @command.timeModifFrom?
        @command.timeFinalFrom = @command.timeModifFrom
    end
    if @command.timeModifTo?
        @command.timeFinalTo = @command.timeModifTo
    end

    if @command.timeFinalFrom > @command.timeFinalTo
      tmpdate=@command.timeFinalFrom
      @command.timeFinalFrom = @command.timeFinalTo
      @command.timeFinalTo = tmpdate
    end

    respond_to do |format|
      if @command.update(command_params)
        format.html { redirect_to commands_during_url, notice: 'La commande a été modifier.' }

      else
        format.html { render :edit }
        format.json { render json: @command.errors, status: :unprocessable_entity }
      end
    end
  end

  def import
    @current_user = current_user
    current_user.commands.import(params[:file])
    redirect_to commands_url, notice: 'Les commandes ont été créé.'
  end


  # DELETE /commands/1
  # DELETE /commands/1.json
  def destroy
    @command.destroy
    respond_to do |format|
      format.html { redirect_to commands_url, notice: 'La commande a été détruite.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_command
      @command = Command.find(params[:id])
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def command_params

        params.require(:command).permit(:name,:adress,:zipcode,:unit,:timeEnterFrom,:dateEnter ,:timeEnterTo,:dateModif,:timeModifFrom ,:timeModifTo ,:commentaire,:statewait,:statedone)

    end
end
