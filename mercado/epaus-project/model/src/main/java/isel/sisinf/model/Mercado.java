package isel.sisinf.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "mercado")
public class Mercado {
    @Id
    @Column(name = "mercado_id", length = 20)
    private String id;

    @Column(name = "descricao", nullable = false)
    private String descricao;

    @Column(name = "nome_curto", nullable = false, length = 50)
    private String nomeCurto;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getDescricao() {
        return descricao;
    }

    public void setDescricao(String descricao) {
        this.descricao = descricao;
    }

    public String getNomeCurto() {
        return nomeCurto;
    }

    public void setNomeCurto(String nomeCurto) {
        this.nomeCurto = nomeCurto;
    }
}
