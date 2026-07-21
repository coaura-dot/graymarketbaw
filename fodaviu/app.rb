require_relative "config/environment"
require "sinatra/base"
require "securerandom"
require "digest"

class BawmcStore < Sinatra::Base
  set :root, File.dirname(__FILE__)
  configure do
    # O Sinatra/rack-protection já faz a derivação interna da chave de
    # sessão a partir do session_secret (não precisamos pré-hashear).
    # Passar um valor já digerido (32 bytes binários) quebra a lógica de
    # rotação de chaves do Rack::Protection::EncryptedCookie. Basta uma
    # string longa e aleatória (>= 32 caracteres).
    # IMPORTANTE: isso precisa ser definido ANTES de "enable :sessions",
    # pois o Sinatra monta o middleware de sessão assim que :sessions é
    # habilitado, usando o valor de session_secret que existir *naquele momento*.
    set :session_secret, ENV.fetch("SESSION_SECRET") { SecureRandom.hex(64) }
    enable :sessions
    set :views, File.join(File.dirname(__FILE__), "views")
    set :public_folder, File.join(File.dirname(__FILE__), "public")
    set :erb, layout: :"layouts/layout"
    if ENV["SINATRA_ENV"] == "test"
      set :show_exceptions, false
      set :raise_errors, true
    end
  end

  # ---------- Helpers ----------
  helpers do
    def usuario_atual
      @usuario_atual ||= Usuario.find_by(id: session[:usuario_id])
    end

    def logado?
      !usuario_atual.nil?
    end

    def exigir_login!
      unless logado?
        session[:erro] = "Você precisa entrar na sua conta para continuar."
        redirect "/login"
      end
    end

    def carrinho
      session[:carrinho] ||= {}
    end

    def formatar_preco(valor)
      "%.2f" % valor.to_f
    end

    def sucesso(msg)
      session[:sucesso] = msg
    end

    def erro(msg)
      session[:erro] = msg
    end

    # Mapeia o produto para um ícone de item do Minecraft, com base em
    # palavras-chave do nome. Cai para um ícone genérico por categoria
    # se nada específico for encontrado.
    ICONES_PRODUTO = {
      /peitoral/i           => "netherite_chestplate",
      /cal[cç]a/i           => "netherite_leggings",
      /bota/i               => "netherite_boots",
      /capacete/i           => "netherite_helmet",
      /machado/i            => "netherite_axe",
      /espada/i             => "netherite_sword",
      /ma[cç]a/i            => "mace",
      /tridente/i           => "trident",
      /bloco de diamante/i  => "diamond_block",
      /diamante/i           => "diamond",
      /bloco de obsidiana/i => "obsidian",
      /bloco de netherite/i => "netherite_block",
      /kit/i                => "shulker_box",
      /cristal/i            => "end_crystal",
    }.freeze

    ICONES_CATEGORIA = {
      "Netherite" => "netherite_sword",
      "Tridente"  => "trident",
      "Maça"      => "mace",
      "Blocos"    => "obsidian",
      "Kits"      => "shulker_box",
      "Diamante"  => "diamond",
    }.freeze

    def icone_produto(produto)
      ICONES_PRODUTO.each do |padrao, arquivo|
        return arquivo if produto.nome =~ padrao
      end
      ICONES_CATEGORIA[produto.categoria] || "chest"
    end
  end

  # ---------- Home / Busca de produtos ----------
  get "/" do
    @termo = params[:q]
    @categoria = params[:categoria]
    @produtos = Produto.includes(:vendedor).busca(@termo)
    @produtos = @produtos.where(categoria: @categoria) if @categoria.present?
    @produtos = @produtos.order(created_at: :desc)
    erb :"produtos/index"
  end

  # ---------- Cadastro / Login / Perfil ----------
  get "/cadastro" do
    @usuario = Usuario.new
    erb :"usuarios/novo"
  end

  post "/cadastro" do
    @usuario = Usuario.new(
      nome: params[:nome],
      email: params[:email],
      cpf: params[:cpf],
      telefone: params[:telefone],
      senha: params[:senha]
    )

    if params[:senha] != params[:senha_confirmacao]
      @usuario.errors.add(:senha, "não confere com a confirmação")
      halt erb(:"usuarios/novo")
    end

    if @usuario.save
      session[:usuario_id] = @usuario.id
      sucesso("Bem-vindo(a) ao BAWMC.net, #{@usuario.nome}! Cadastro realizado com sucesso.")
      redirect "/"
    else
      erb :"usuarios/novo"
    end
  end

  get "/login" do
    erb :"usuarios/login"
  end

  post "/login" do
    usuario = Usuario.autenticar(params[:email], params[:senha])
    if usuario
      session[:usuario_id] = usuario.id
      sucesso("Login realizado com sucesso. Boas compras em BAWMC.net!")
      redirect "/"
    else
      erro("E-mail ou senha inválidos.")
      erb :"usuarios/login"
    end
  end

  post "/logout" do
    session.clear
    sucesso("Você saiu da sua conta.")
    redirect "/"
  end

  get "/perfil" do
    exigir_login!
    @usuario = usuario_atual
    erb :"usuarios/editar"
  end

  post "/perfil" do
    exigir_login!
    @usuario = usuario_atual
    atributos = {
      nome: params[:nome],
      email: params[:email],
      cpf: params[:cpf],
      telefone: params[:telefone]
    }
    atributos[:senha] = params[:senha] if params[:senha].present?

    if @usuario.update(atributos)
      sucesso("Perfil atualizado com sucesso.")
      redirect "/perfil"
    else
      erb :"usuarios/editar"
    end
  end

  # ---------- Vendedor: CRUD de produtos ----------
  get "/meus_produtos" do
    exigir_login!
    @produtos = usuario_atual.produtos.order(created_at: :desc)
    erb :"produtos/meus"
  end

  get "/produtos/novo" do
    exigir_login!
    @produto = Produto.new
    erb :"produtos/novo"
  end

  post "/produtos" do
    exigir_login!
    @produto = usuario_atual.produtos.new(
      nome: params[:nome],
      descricao: params[:descricao],
      preco: params[:preco],
      estoque: params[:estoque],
      categoria: params[:categoria]
    )

    if @produto.save
      sucesso("Produto \"#{@produto.nome}\" cadastrado com sucesso!")
      redirect "/meus_produtos"
    else
      erb :"produtos/novo"
    end
  end

  get "/produtos/:id" do
    @produto = Produto.find_by(id: params[:id])
    halt 404, erb(:"produtos/nao_encontrado") unless @produto
    erb :"produtos/mostrar"
  end

  get "/produtos/:id/editar" do
    exigir_login!
    @produto = usuario_atual.produtos.find_by(id: params[:id])
    halt 404, erb(:"produtos/nao_encontrado") unless @produto
    erb :"produtos/editar"
  end

  post "/produtos/:id" do
    exigir_login!
    @produto = usuario_atual.produtos.find_by(id: params[:id])
    halt 404, erb(:"produtos/nao_encontrado") unless @produto

    if @produto.update(
      nome: params[:nome],
      descricao: params[:descricao],
      preco: params[:preco],
      estoque: params[:estoque],
      categoria: params[:categoria]
    )
      sucesso("Produto atualizado com sucesso.")
      redirect "/meus_produtos"
    else
      erb :"produtos/editar"
    end
  end

  post "/produtos/:id/excluir" do
    exigir_login!
    @produto = usuario_atual.produtos.find_by(id: params[:id])
    halt 404, erb(:"produtos/nao_encontrado") unless @produto
    @produto.destroy
    sucesso("Produto removido do catálogo.")
    redirect "/meus_produtos"
  end

  # ---------- Comprador: carrinho ----------
  # OBS: rotas mais específicas ("/carrinho/finalizar") precisam vir ANTES
  # da rota curinga "/carrinho/:produto_id", senão o Sinatra casa a rota
  # errada primeiro (produto_id acabaria sendo "finalizar").
  get "/carrinho" do
    exigir_login!
    @itens = carrinho.map do |produto_id, quantidade|
      produto = Produto.find_by(id: produto_id)
      next nil unless produto
      { produto: produto, quantidade: quantidade.to_i }
    end.compact
    @total = @itens.sum { |i| i[:produto].preco * i[:quantidade] }
    erb :"carrinho/mostrar"
  end

  post "/carrinho/finalizar" do
    exigir_login!

    if carrinho.empty?
      erro("Seu carrinho está vazio.")
      redirect "/carrinho"
    end

    begin
      venda = Venda.finalizar_compra!(
        comprador: usuario_atual,
        carrinho: carrinho,
        endereco_entrega: params[:endereco_entrega]
      )
      session[:carrinho] = {}
      sucesso("Compra finalizada com sucesso! Pedido ##{venda.id}.")
      redirect "/minhas_compras"
    rescue => e
      erro("Não foi possível finalizar a compra: estoque insuficiente para um ou mais itens.")
      redirect "/carrinho"
    end
  end

  post "/carrinho/:produto_id/remover" do
    exigir_login!
    novo_carrinho = carrinho.dup
    novo_carrinho.delete(params[:produto_id].to_s)
    session[:carrinho] = novo_carrinho
    sucesso("Item removido do carrinho.")
    redirect "/carrinho"
  end

  post "/carrinho/:produto_id" do
    exigir_login!
    produto = Produto.find_by(id: params[:produto_id])
    halt 404 unless produto

    quantidade = params[:quantidade].to_i
    quantidade = 1 if quantidade < 1

    novo_carrinho = carrinho.dup
    chave = params[:produto_id].to_s
    novo_carrinho[chave] = novo_carrinho[chave].to_i + quantidade
    session[:carrinho] = novo_carrinho
    sucesso("#{produto.nome} adicionado ao carrinho.")
    redirect "/carrinho"
  end

  # ---------- Comprador: minhas compras ----------
  get "/minhas_compras" do
    exigir_login!
    @vendas = usuario_atual.compras.includes(item_vendas: :produto).order(created_at: :desc)
    erb :"vendas/minhas_compras"
  end

  post "/compras/:id/cancelar" do
    exigir_login!
    venda = usuario_atual.compras.find_by(id: params[:id])
    halt 404 unless venda

    if venda.cancelar!
      sucesso("Compra ##{venda.id} cancelada e estoque estornado.")
    else
      erro("Só é possível cancelar compras com status pendente.")
    end
    redirect "/minhas_compras"
  end

  # ---------- Vendedor: vendas recebidas ----------
  get "/vendas_recebidas" do
    exigir_login!
    @vendas = usuario_atual.vendas.includes(:comprador, item_vendas: :produto).order(created_at: :desc)
    erb :"vendas/recebidas"
  end

  post "/vendas/:id/avancar" do
    exigir_login!
    venda = usuario_atual.vendas.find_by(id: params[:id])
    halt 404 unless venda

    if venda.avancar_status!
      sucesso("Status da venda ##{venda.id} atualizado para \"#{venda.status}\".")
    else
      erro("Esta venda já está no status final ou não pode avançar.")
    end
    redirect "/vendas_recebidas"
  end

  run! if app_file == $0
end