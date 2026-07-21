class Produto < ActiveRecord::Base
  belongs_to :vendedor, class_name: "Usuario", inverse_of: :produtos
  has_many :item_vendas, dependent: :destroy
  has_many :vendas, through: :item_vendas

  validates :nome, presence: true
  validates :preco, numericality: { greater_than: 0 }
  validates :estoque, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  CATEGORIAS = ["Netherite", "Tridente", "Maça", "Blocos", "Kits", "Diamante"].freeze

  scope :busca, ->(termo) {
    termo.present? ? where("lower(nome) LIKE :t OR lower(descricao) LIKE :t OR lower(categoria) LIKE :t",
                            t: "%#{termo.to_s.downcase}%") : all
  }

  def disponivel?
    estoque > 0
  end
end
