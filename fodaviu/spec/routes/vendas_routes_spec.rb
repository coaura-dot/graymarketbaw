require "spec_helper"
require "rack/test"
require_relative "../../app"

RSpec.describe "Rotas de carrinho e vendas" do
  include Rack::Test::Methods

  def app
    BawmcStore
  end

  def login(email, senha)
    post "/login", email: email, senha: senha
  end

  describe "POST /carrinho/:produto_id" do
    it "adiciona um produto ao carrinho do usuário logado" do
      vendedor = cria_usuario
      produto = cria_produto(vendedor: vendedor, estoque: 5)
      cria_usuario(email: "comprador@bawmc.net", senha: "123456")
      login("comprador@bawmc.net", "123456")

      post "/carrinho/#{produto.id}", quantidade: "2"
      expect(last_response.status).to eq(302)

      get "/carrinho"
      expect(last_response.body).to include(produto.nome)
    end
  end

  describe "POST /carrinho/:produto_id/remover" do
    it "remove um item do carrinho" do
      vendedor = cria_usuario
      produto = cria_produto(vendedor: vendedor, estoque: 5)
      cria_usuario(email: "comprador2@bawmc.net", senha: "123456")
      login("comprador2@bawmc.net", "123456")

      post "/carrinho/#{produto.id}", quantidade: "1"
      post "/carrinho/#{produto.id}/remover"

      get "/carrinho"
      expect(last_response.body).not_to include(produto.nome)
    end
  end

  describe "POST /carrinho/finalizar" do
    it "finaliza a compra, debita estoque e cria a venda" do
      vendedor = cria_usuario
      produto = cria_produto(vendedor: vendedor, preco: 25, estoque: 5)
      comprador = cria_usuario(email: "final@bawmc.net", senha: "123456")
      login("final@bawmc.net", "123456")

      post "/carrinho/#{produto.id}", quantidade: "2"

      expect {
        post "/carrinho/finalizar", endereco_entrega: "Casa do Steve"
      }.to change { Venda.count }.by(1)

      expect(last_response.status).to eq(302)
      expect(last_response.location).to include("/minhas_compras")
      expect(produto.reload.estoque).to eq(3)
    end

    it "não permite finalizar com carrinho vazio" do
      cria_usuario(email: "vazio@bawmc.net", senha: "123456")
      login("vazio@bawmc.net", "123456")

      expect {
        post "/carrinho/finalizar"
      }.not_to change { Venda.count }
      expect(last_response.status).to eq(302)
      expect(last_response.location).to include("/carrinho")
    end
  end

  describe "GET /minhas_compras" do
    it "lista as compras do usuário autenticado" do
      vendedor = cria_usuario
      comprador = cria_usuario(email: "compras@bawmc.net", senha: "123456")
      cria_venda(comprador: comprador, vendedor: vendedor)
      login("compras@bawmc.net", "123456")

      get "/minhas_compras"
      expect(last_response.status).to eq(200)
    end
  end

  describe "POST /compras/:id/cancelar" do
    it "cancela uma compra pendente do próprio comprador" do
      vendedor = cria_usuario
      comprador = cria_usuario(email: "cancela@bawmc.net", senha: "123456")
      produto = cria_produto(vendedor: vendedor, estoque: 5)
      venda = cria_venda(comprador: comprador, vendedor: vendedor, status: "pendente")
      cria_item_venda(venda: venda, produto: produto, quantidade: 2)
      login("cancela@bawmc.net", "123456")

      post "/compras/#{venda.id}/cancelar"
      expect(last_response.status).to eq(302)
      expect(venda.reload.status).to eq("cancelada")
      expect(produto.reload.estoque).to eq(7)
    end

    it "não cancela uma compra que não pertence ao usuário" do
      vendedor = cria_usuario
      dono = cria_usuario
      venda = cria_venda(comprador: dono, vendedor: vendedor, status: "pendente")
      cria_usuario(email: "outro@bawmc.net", senha: "123456")
      login("outro@bawmc.net", "123456")

      post "/compras/#{venda.id}/cancelar"
      expect(last_response.status).to eq(404)
    end
  end

  describe "GET /vendas_recebidas" do
    it "lista as vendas recebidas pelo vendedor autenticado" do
      vendedor = cria_usuario(email: "vendedor@bawmc.net", senha: "123456")
      comprador = cria_usuario
      cria_venda(comprador: comprador, vendedor: vendedor)
      login("vendedor@bawmc.net", "123456")

      get "/vendas_recebidas"
      expect(last_response.status).to eq(200)
    end
  end

  describe "POST /vendas/:id/avancar" do
    it "avança o status de uma venda do próprio vendedor" do
      vendedor = cria_usuario(email: "avanca@bawmc.net", senha: "123456")
      comprador = cria_usuario
      venda = cria_venda(comprador: comprador, vendedor: vendedor, status: "pendente")
      login("avanca@bawmc.net", "123456")

      post "/vendas/#{venda.id}/avancar"
      expect(last_response.status).to eq(302)
      expect(venda.reload.status).to eq("paga")
    end

    it "retorna 404 para venda que não pertence ao vendedor autenticado" do
      vendedor = cria_usuario
      comprador = cria_usuario
      venda = cria_venda(comprador: comprador, vendedor: vendedor, status: "pendente")
      cria_usuario(email: "intrusovenda@bawmc.net", senha: "123456")
      login("intrusovenda@bawmc.net", "123456")

      post "/vendas/#{venda.id}/avancar"
      expect(last_response.status).to eq(404)
    end
  end
end
