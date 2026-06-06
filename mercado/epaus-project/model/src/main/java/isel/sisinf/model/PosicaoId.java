package isel.sisinf.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class PosicaoId implements Serializable {
    @Column(name = "portefolio")
    private Long portefolio;

    @Column(name = "instrumento_isin", length = 12)
    private String instrumentoIsin;

    public Long getPortefolio() {
        return portefolio;
    }

    public void setPortefolio(Long portefolio) {
        this.portefolio = portefolio;
    }

    public String getInstrumentoIsin() {
        return instrumentoIsin;
    }

    public void setInstrumentoIsin(String instrumentoIsin) {
        this.instrumentoIsin = instrumentoIsin;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (!(obj instanceof PosicaoId other)) {
            return false;
        }
        return Objects.equals(portefolio, other.portefolio)
                && Objects.equals(instrumentoIsin, other.instrumentoIsin);
    }

    @Override
    public int hashCode() {
        return Objects.hash(portefolio, instrumentoIsin);
    }
}
