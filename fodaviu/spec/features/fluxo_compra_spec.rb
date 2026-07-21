require "spec_helper"
require "capybara/rspec"
require_relative "../../app"

Capybara.app = BawmcStore
Capybara.default_driver = :rack_test

RSpec.describe "Fluxo completo de compra", type: :feature do
  it "cadastro, publicação de produto, compra e avanço de status até a entrega" do
    # --- Vendedor se cadastra ---
    visit "/cadastro"
    fill_in "nome", with: "Loja BAWMC"
    fill_in "email", with: "loja.feature@bawmc.net"
    fill_in "cpf", with: "111.111.111-11"
    fill_in "senha", with: "123456"
    fill_in "senha_confirmacao", with: "123456"
    click_button "Criar conta"

    expect(page).to have_content("Bem-vindo")

    # --- Vendedor publica um produto ---
    visit "/produtos/novo"
    fill_in "nome", with: "Espada de Netherite Encantada"
    fill_in "descricao", with: "Sharpness V, Fire Aspect III"
    fill_in "preco", with: "50"
    fill_in "estoque", with: "4"
    click_button "Cadastrar"

    expect(page).to have_content("Espada de Netherite Encantada")

    click_button("Sair")

    # --- Comprador se cadastra ---
    visit "/cadastro"
    fill_in "nome", with: "Steve Comprador"
    fill_in "email", with: "steve.feature@bawmc.net"
    fill_in "cpf", with: "222.222.222-22"
    fill_in "senha", with: "123456"
    fill_in "senha_confirmacao", with: "123456"
    click_button "Criar conta"

    expect(page).to have_content("Bem-vindo")

    # --- Comprador encontra o produto e adiciona ao carrinho ---
    produto = Produto.find_by(nome: "Espada de Netherite Encantada")
    visit "/produtos/#{produto.id}"
    fill_in "quantidade", with: "2"
    click_button "Adicionar ao carrinho"

    expect(page).to have_content("Espada de Netherite Encantada")

    # --- Finaliza a compra ---
    fill_in "endereco_entrega", with: "Spawn, x:0 y:70 z:0"
    click_button "Finalizar compra"

    expect(page).to have_content("Compra finalizada com sucesso")
    expect(produto.reload.estoque).to eq(2)

    venda = Venda.last
    expect(venda.status).to eq("pendente")

    click_button("Sair")

    # --- Vendedor avança o status da venda até a entrega ---
    visit "/login"
    fill_in "email", with: "loja.feature@bawmc.net"
    fill_in "senha", with: "123456"
    click_button "Entrar"

    visit "/vendas_recebidas"
    click_button "Avançar para \"paga\""
    expect(venda.reload.status).to eq("paga")

    visit "/vendas_recebidas"
    click_button "Avançar para \"enviada\""
    expect(venda.reload.status).to eq("enviada")

    visit "/vendas_recebidas"
    click_button "Avançar para \"entregue\""
    expect(venda.reload.status).to eq("entregue")

    visit "/vendas_recebidas"
    expect(page).to have_content("Pedido finalizado.")
  end
end
