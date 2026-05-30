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
import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.EntityTransaction;
import jakarta.persistence.LockModeType;
import jakarta.persistence.OptimisticLockException;
import jakarta.persistence.Persistence;
import jakarta.persistence.Query;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Dal implements AutoCloseable
{
    private final EntityManagerFactory emf;
    private final EntityManager em;

    public record PositionRow(
            long portfolioId,
            String portfolioName,
            String isin,
            BigDecimal quantity,
            BigDecimal currentValue,
            BigDecimal positionTotal,
            BigDecimal portfolioTotal,
            BigDecimal dailyVariationPercent
    ) {
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
            Query query = em.createNativeQuery("""
                    INSERT INTO contacto_cliente
                    (nif, carta_cidadao, nome, tipo_contacto, contacto, descricao)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """);
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
            Query query = em.createNativeQuery("""
                    INSERT INTO portefolio (cliente_nif, nome)
                    VALUES (?, ?)
                    """);
            query.setParameter(1, nif);
            query.setParameter(2, name);
            query.executeUpdate();
        });
    }

    public List<PositionRow> listPositionsByClient(String nif) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery("""
                SELECT pf.portefolio_id,
                       pf.nome,
                       info.instrumento_isin,
                       info.quantidade,
                       info.valor_actual,
                       ROUND(info.quantidade * info.valor_actual, 2) AS valor_posicao,
                       pf.valor_total,
                       info.percentagem_variacao_diaria
                FROM portefolio pf
                JOIN LATERAL fx_portefolio_info(pf.portefolio_id) info ON TRUE
                WHERE pf.cliente_nif = ?
                ORDER BY pf.portefolio_id, info.instrumento_isin
                """)
                .setParameter(1, nif)
                .getResultList();

        return rows.stream()
                .map(row -> new PositionRow(
                        ((Number) row[0]).longValue(),
                        (String) row[1],
                        (String) row[2],
                        (BigDecimal) row[3],
                        (BigDecimal) row[4],
                        (BigDecimal) row[5],
                        (BigDecimal) row[6],
                        (BigDecimal) row[7]))
                .toList();
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
