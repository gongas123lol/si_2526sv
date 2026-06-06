package isel.sisinf.model;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.Table;

import java.math.BigDecimal;

@Entity
@Table(name = "posicao")
public class Posicao {
    @EmbeddedId
    private PosicaoId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("portefolio")
    @JoinColumn(name = "portefolio", nullable = false)
    private Portefolio portefolio;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("instrumentoIsin")
    @JoinColumn(name = "instrumento_isin", nullable = false)
    private Instrumento instrumento;

    @Column(name = "quantidade", nullable = false)
    private BigDecimal quantidade;

    public PosicaoId getId() {
        return id;
    }

    public void setId(PosicaoId id) {
        this.id = id;
    }

    public Portefolio getPortefolio() {
        return portefolio;
    }

    public void setPortefolio(Portefolio portefolio) {
        this.portefolio = portefolio;
    }

    public Instrumento getInstrumento() {
        return instrumento;
    }

    public void setInstrumento(Instrumento instrumento) {
        this.instrumento = instrumento;
    }

    public BigDecimal getQuantidade() {
        return quantidade;
    }

    public void setQuantidade(BigDecimal quantidade) {
        this.quantidade = quantidade;
    }
}
