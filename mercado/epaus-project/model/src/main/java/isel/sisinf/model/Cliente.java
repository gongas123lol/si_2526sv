package isel.sisinf.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

@Entity
@Table(name = "cliente")
public class Cliente {
    @Id
    @Column(name = "nif", length = 20)
    private String nif;

    @Column(name = "cartao_cidadao", nullable = false, unique = true, length = 20)
    private String cartaoCidadao;

    @Column(name = "nome", nullable = false, length = 256)
    private String nome;

    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    public String getNif() {
        return nif;
    }

    public void setNif(String nif) {
        this.nif = nif;
    }

    public String getCartaoCidadao() {
        return cartaoCidadao;
    }

    public void setCartaoCidadao(String cartaoCidadao) {
        this.cartaoCidadao = cartaoCidadao;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public Long getVersion() {
        return version;
    }
}
