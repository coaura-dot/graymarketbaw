class Usuario < ActiveRecord::Base
  attr_accessor :senha, :senha_confirmacao

  before_save :gerar_senha_hash, if: -> { senha.present? }

  has_many :produtos, foreign_key: :vendedor_id, dependent: :destroy, inverse_of: :vendedor
  has_many :compras, class_name: "Venda", foreign_key: :comprador_id, dependent: :destroy, inverse_of: :comprador
  has_many :vendas, class_name: "Venda", foreign_key: :vendedor_id, dependent: :destroy, inverse_of: :vendedor

  validates :nome, presence: true
  validates :cpf, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                     format: { with: URI::MailTo::EMAIL_REGEXP, message: "formato inválido" }
  validates :senha, length: { minimum: 6 }, if: -> { new_record? || senha.present? }
  validates :senha, presence: true, on: :create

  # Vendedor é quem possui pelo menos um produto cadastrado
  def vendedor?
    produtos.exists?
  end

  # Comprador é quem possui pelo menos uma compra realizada
  def comprador?
    compras.exists?
  end

  def self.autenticar(email, senha)
    usuario = find_by("lower(email) = ?", email.to_s.downcase)
    return nil unless usuario && usuario.senha_hash.present?

    BCrypt::Password.new(usuario.senha_hash) == senha ? usuario : nil
  end

  private

  def gerar_senha_hash
    self.senha_hash = BCrypt::Password.create(senha)
  end
end
