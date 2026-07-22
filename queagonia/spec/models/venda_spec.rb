require "spec_helper"

RSpec.describe Venda do
  describe "validações" do
    it "é válido com status permitido" do
      venda = Venda.new(comprador: cria_usuario, vendedor: cria_usuario, status: "pendente")
      expect(venda).to be_valid
    end

    it "é inválido com status fora da lista permitida" do
      venda = Venda.new(comprador: cria_usuario, vendedor: cria_usuario, status: "inexistente")
      expect(venda).not_to be_valid
      expect(venda.errors[:status]).not_to be_empty
    end

    it "define pendente como status padrão na criação" do
      venda = Venda.create!(comprador: cria_usuario, vendedor: cria_usuario)
      expect(venda.status).to eq("pendente")
    end

    it "define a data automaticamente na criação" do
      venda = Venda.create!(comprador: cria_usuario, vendedor: cria_usuario)
      expect(venda.data).to eq(Date.today)
    end

    it "é inválido quando comprador e vendedor são o mesmo usuário" do
      usuario = cria_usuario
      venda = Venda.new(comprador: usuario, vendedor: usuario, status: "pendente")
      expect(venda).not_to be_valid
      expect(venda.errors[:comprador_id]).not_to be_empty
    end
  end

  describe "#avancar_status!" do
    it "segue a sequência pendente -> paga -> enviada -> entregue" do
      venda = cria_venda(comprador: cria_usuario, vendedor: cria_usuario, status: "pendente")

      expect { venda.avancar_status! }.to change { venda.reload.status }.from("pendente").to("paga")
      expect { venda.avancar_status! }.to change { venda.reload.status }.from("paga").to("enviada")
      expect { venda.avancar_status! }.to change { venda.reload.status }.from("enviada").to("entregue")
    end

    it "retorna false e não altera o status quando já está entregue" do
      venda = cria_venda(comprador: cria_usuario, vendedor: cria_usuario, status: "entregue")
      expect(venda.avancar_status!).to be false
      expect(venda.reload.status).to eq("entregue")
    end

    it "retorna false quando o status é cancelada" do
      venda = cria_venda(comprador: cria_usuario, vendedor: cria_usuario, status: "cancelada")
      expect(venda.avancar_status!).to be false
    end
  end

  describe "#cancelavel? e #cancelar!" do
    it "é cancelável apenas quando pendente" do
      pendente = cria_venda(comprador: cria_usuario, vendedor: cria_usuario, status: "pendente")
      paga = cria_venda(comprador: cria_usuario, vendedor: cria_usuario, status: "paga")

      expect(pendente.cancelavel?).to be true
      expect(paga.cancelavel?).to be false
    end

    it "estorna o estoque dos produtos ao cancelar" do
      vendedor = cria_usuario
      comprador = cria_usuario
      produto = cria_produto(vendedor: vendedor, estoque: 5)
      venda = cria_venda(comprador: comprador, vendedor: vendedor, status: "pendente")
      cria_item_venda(venda: venda, produto: produto, quantidade: 2)

      expect { venda.cancelar! }.to change { produto.reload.estoque }.by(2)
      expect(venda.reload.status).to eq("cancelada")
    end

    it "não cancela uma venda que não está pendente" do
      venda = cria_venda(comprador: cria_usuario, vendedor: cria_usuario, status: "enviada")
      expect(venda.cancelar!).to be false
      expect(venda.reload.status).to eq("enviada")
    end
  end

  describe ".finalizar_compra!" do
    it "debita o estoque e calcula o valor_total corretamente" do
      vendedor = cria_usuario
      comprador = cria_usuario
      produto1 = cria_produto(vendedor: vendedor, preco: 10, estoque: 5)
      produto2 = cria_produto(vendedor: vendedor, nome: "Bloco de Diamante", preco: 20, estoque: 3)

      carrinho = { produto1.id.to_s => 2, produto2.id.to_s => 1 }

      venda = Venda.finalizar_compra!(comprador: comprador, carrinho: carrinho)

      expect(venda.valor_total.to_f).to eq(40.0)
      expect(produto1.reload.estoque).to eq(3)
      expect(produto2.reload.estoque).to eq(2)
      expect(venda.item_vendas.count).to eq(2)
      expect(venda.vendedor).to eq(vendedor)
      expect(venda.status).to eq("pendente")
    end

    it "falha a transação por inteiro quando um item não tem estoque suficiente" do
      vendedor = cria_usuario
      comprador = cria_usuario
      produto1 = cria_produto(vendedor: vendedor, preco: 10, estoque: 5)
      produto2 = cria_produto(vendedor: vendedor, nome: "Bloco Raro", preco: 20, estoque: 1)

      carrinho = { produto1.id.to_s => 2, produto2.id.to_s => 10 }

      expect {
        expect { Venda.finalizar_compra!(comprador: comprador, carrinho: carrinho) }.to raise_error
      }.not_to change { Venda.count }

      # Nenhum estoque deve ter sido debitado, pois a transação falhou por inteiro
      expect(produto1.reload.estoque).to eq(5)
      expect(produto2.reload.estoque).to eq(1)
    end

    it "levanta erro quando o carrinho está vazio" do
      comprador = cria_usuario
      expect {
        Venda.finalizar_compra!(comprador: comprador, carrinho: {})
      }.to raise_error("Carrinho vazio")
    end

    it "grava o endereco_entrega quando informado" do
      vendedor = cria_usuario
      comprador = cria_usuario
      produto = cria_produto(vendedor: vendedor, preco: 10, estoque: 5)

      venda = Venda.finalizar_compra!(
        comprador: comprador,
        carrinho: { produto.id.to_s => 1 },
        endereco_entrega: "Vila BAWMC, casa 7"
      )

      expect(venda.endereco_entrega).to eq("Vila BAWMC, casa 7")
    end
  end
end
