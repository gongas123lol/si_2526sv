/*
MIT License

Copyright (c) 2025-2026, Nuno Datia, ISEL

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
package isel.sisinf.jpa;

import isel.sisinf.model.Cliente;
import isel.sisinf.model.Portefolio;
import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.EntityTransaction;
import jakarta.persistence.LockModeType;
import jakarta.persistence.OptimisticLockException;
import jakarta.persistence.Persistence;
import jakarta.persistence.Query;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Dal implements AutoCloseable
{
    private final EntityManagerFactory emf;
    private final EntityManager em;

    public static class PositionRow {
        private final long portfolioId;
        private final String portfolioName;
        private final String isin;
        private final BigDecimal quantity;
        private final BigDecimal currentValue;
        private final BigDecimal positionTotal;
        private final BigDecimal portfolioTotal;
        private final BigDecimal dailyVariationPercent;

        public PositionRow(long portfolioId, String portfolioName, String isin,
                           BigDecimal quantity, BigDecimal currentValue,
                           BigDecimal positionTotal, BigDecimal portfolioTotal,
                           BigDecimal dailyVariationPercent) {
            this.portfolioId = portfolioId;
            this.portfolioName = portfolioName;
            this.isin = isin;
            this.quantity = quantity;
            this.currentValue = currentValue;
            this.positionTotal = positionTotal;
            this.portfolioTotal = portfolioTotal;
            this.dailyVariationPercent = dailyVariationPercent;
        }

        public long portfolioId() { return portfolioId; }
        public String portfolioName() { return portfolioName; }
        public String isin() { return isin; }
        public BigDecimal quantity() { return quantity; }
        public BigDecimal currentValue() { return currentValue; }
        public BigDecimal positionTotal() { return positionTotal; }
        public BigDecimal portfolioTotal() { return portfolioTotal; }
        public BigDecimal dailyVariationPercent() { return dailyVariationPercent; }
    }

    public Dal() {
        Map<String, String> properties = new HashMap<>();
        properties.put("jakarta.persistence.jdbc.url",
                System.getenv().getOrDefault("SI_DB_URL", "jdbc:postgresql://localhost:5432/postgres"));
        properties.put("jakarta.persistence.jdbc.user",
                System.getenv().getOrDefault("SI_DB_USER", "postgres"));
        properties.put("jakarta.persistence.jdbc.password",
                System.getenv().getOrDefault("SI_DB_PASSWORD", "postgres"));
        this.emf = Persistence.createEntityManagerFactory("projectSI", properties);
        this.em = emf.createEntityManager();
    }

    public static String version(){ return "1.0";}

    public void createClientWithContact(String nif, String citizenCard, String name,
                                        String contactType, String contact, String description) {
        inTransaction(() -> {
            String sql = "INSERT INTO contacto_cliente " +
                    "(nif, carta_cidadao, nome, tipo_contacto, contacto, descricao) " +
                    "VALUES (?, ?, ?, ?, ?, ?)";
            Query query = em.createNativeQuery(sql);
            query.setParameter(1, nif);
            query.setParameter(2, citizenCard);
            query.setParameter(3, name);
            query.setParameter(4, contactType);
            query.setParameter(5, contact);
            query.setParameter(6, description);
            query.executeUpdate();
        });
    }

    public void createPortfolio(String nif, String name) {
        inTransaction(() -> {
            Cliente cliente = em.find(Cliente.class, nif);
            if (cliente == null) {
                throw new IllegalArgumentException("Cliente inexistente: " + nif);
            }

            Portefolio portefolio = new Portefolio();
            portefolio.setCliente(cliente);
            portefolio.setNome(name);
            em.persist(portefolio);
        });
    }

    public List<PositionRow> listPositionsByClient(String nif) {
        String sql = "SELECT pf.portefolio_id, " +
                "pf.nome, " +
                "info.instrumento_isin, " +
                "info.quantidade, " +
                "info.valor_actual, " +
                "ROUND(info.quantidade * info.valor_actual, 2) AS valor_posicao, " +
                "pf.valor_total, " +
                "info.percentagem_variacao_diaria " +
                "FROM portefolio pf " +
                "JOIN LATERAL fx_portefolio_info(pf.portefolio_id) info ON TRUE " +
                "WHERE pf.cliente_nif = ? " +
                "ORDER BY pf.portefolio_id, info.instrumento_isin";

        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery(sql)
                .setParameter(1, nif)
                .getResultList();

        List<PositionRow> result = new ArrayList<>();
        for (Object[] row : rows) {
            result.add(new PositionRow(
                    ((Number) row[0]).longValue(),
                    (String) row[1],
                    (String) row[2],
                    (BigDecimal) row[3],
                    (BigDecimal) row[4],
                    (BigDecimal) row[5],
                    (BigDecimal) row[6],
                    (BigDecimal) row[7]));
        }
        return result;
    }

    public void updateDailyValues() {
        inTransaction(() -> em.createNativeQuery("CALL p_actualizaValorDiario()").executeUpdate());
    }

    public Cliente findClient(String nif) {
        return em.find(Cliente.class, nif);
    }

    public void updateClient(String nif, String citizenCard, String name) {
        try {
            inTransaction(() -> {
                Cliente cliente = em.find(Cliente.class, nif, LockModeType.OPTIMISTIC);
                if (cliente == null) {
                    throw new IllegalArgumentException("Cliente inexistente: " + nif);
                }
                cliente.setCartaoCidadao(citizenCard);
                cliente.setNome(name);
            });
        } catch (OptimisticLockException ex) {
            throw new IllegalStateException("O cliente foi alterado por outra transaccao. Repita a operacao.", ex);
        }
    }

    private void inTransaction(Runnable work) {
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            work.run();
            tx.commit();
        } catch (RuntimeException ex) {
            if (tx.isActive()) {
                tx.rollback();
            }
            throw ex;
        }
    }

    @Override
    public void close() {
        if (em.isOpen()) {
            em.close();
        }
        if (emf.isOpen()) {
            emf.close();
        }
    }
}
