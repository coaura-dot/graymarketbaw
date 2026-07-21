class Venda < ActiveRecord::Base
  STATUSES = %w[pendente paga enviada entregue cancelada].freeze

  belongs_to :comprador, class_name: "Usuario", inverse_of: :compras
  belongs_to :vendedor, class_name: "Usuario", inverse_of: :vendas
  has_many :item_vendas, dependent: :destroy
  has_many :produtos, through: :item_vendas

  validates :status, inclusion: { in: STATUSES }
  validates :data, presence: true
  validate :comprador_diferente_do_vendedor

  before_validation :definir_data, on: :create
  before_validation :definir_status_padrao, on: :create

  # Avança a situação da venda seguindo a sequência natural até a entrega
  SEQUENCIA = %w[pendente paga enviada entregue].freeze

  def proximo_status
    idx = SEQUENCIA.index(status)
    return nil if idx.nil? || idx == SEQUENCIA.length - 1

    SEQUENCIA[idx + 1]
  end

  def avancar_status!
    prox = proximo_status
    return false unless prox

    update(status: prox)
  end

  def cancelavel?
    status == "pendente"
  end

  def cancelar!
    return false unless cancelavel?

    ActiveRecord::Base.transaction do
      item_vendas.each do |item|
        item.produto.increment!(:estoque, item.quantidade)
      end
      update!(status: "cancelada")
    end
    true
  end

  def recalcular_total!
    update_column(:valor_total, item_vendas.sum("quantidade * preco_unitario"))
  end

  # Finaliza uma compra a partir de um carrinho { produto_id => quantidade }.
  # Debita o estoque e calcula o valor total dentro de uma transação que
  # falha por completo caso algum item não possa ser reservado.
  def self.finalizar_compra!(comprador:, carrinho:, endereco_entrega: nil)
    raise "Carrinho vazio" if carrinho.blank?

    produto_ids = carrinho.keys.map(&:to_i)
    vendedor_ids = Produto.where(id: produto_ids).distinct.pluck(:vendedor_id)
    raise "Carrinho deve conter produtos de um único vendedor" if vendedor_ids.length > 1

    venda = nil
    transaction do
      venda = Venda.create!(
        comprador: comprador,
        vendedor_id: vendedor_ids.first,
        status: "pendente",
        endereco_entrega: endereco_entrega
      )

      carrinho.each do |produto_id, quantidade|
        quantidade = quantidade.to_i
        produto = Produto.lock.find(produto_id)
        raise ActiveRecord::RecordInvalid.new(produto) if produto.estoque < quantidade

        produto.decrement!(:estoque, quantidade)

        ItemVenda.create!(
          venda: venda,
          produto: produto,
          quantidade: quantidade,
          preco_unitario: produto.preco
        )
      end

      venda.recalcular_total!
    end

    venda
  end

  private

  def definir_data
    self.data ||= Date.today
  end

  def definir_status_padrao
    self.status = "pendente" if status.blank?
  end

  def comprador_diferente_do_vendedor
    return if comprador_id.blank? || vendedor_id.blank?

    errors.add(:comprador_id, "não pode ser igual ao vendedor") if comprador_id == vendedor_id
  end
end
