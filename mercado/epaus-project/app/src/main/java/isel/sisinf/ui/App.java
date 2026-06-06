/*
MIT License

Copyright (c) 2025-2026, Nuno Datia, Matilde Pato, ISEL

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
package isel.sisinf.ui;

import isel.sisinf.jpa.Dal;
import isel.sisinf.model.Cliente;

import java.util.List;
import java.util.Scanner;
import java.util.HashMap;

/**
 * 
 * Didactic material to support 
 * to the curricular unit of 
 * Introduction to Information Systems 
 *
 * The examples may not be complete and/or totally correct.
 * They are made available for teaching and learning purposes and 
 * any inaccuracies are the subject of debate.
 */

interface DbWorker
{
    void doWork();
}
class UI implements AutoCloseable
{
    private enum Option
    {
        // DO NOT CHANGE ANYTHING!
        Unknown,
        Exit,
        createClient,
        createPortfolio,
        listPositions,
        updateInvestments,
        updateClient,
        about
    }
    private static UI __instance = null;
    private static Scanner __s = null;
  
    private HashMap<Option,DbWorker> __dbMethods;

    private UI()
    {
        // DO NOT CHANGE ANYTHING!
        __dbMethods = new HashMap<Option,DbWorker>();
        __dbMethods.put(Option.createClient, () -> UI.this.createClient());
        __dbMethods.put(Option.createPortfolio, () -> UI.this.createPortfolio()); 
        __dbMethods.put(Option.listPositions, () -> UI.this.listPositions());
        __dbMethods.put(Option.updateInvestments, () -> UI.this.updateInvestments());
        __dbMethods.put(Option.updateClient, () ->  UI.this.updateClient());
        __dbMethods.put(Option.about, new DbWorker() {public void doWork() {UI.this.about();}});
    }

    public static UI getInstance()
    {
        // DO NOT CHANGE ANYTHING!
        if(__instance == null)
        {
            __instance = new UI();
        }
        return __instance;
    }

    public static Scanner getScanner()
    {
        if(__s == null)
        {
            __s = new Scanner(System.in);
        }
        return __s;
    }

    private Option DisplayMenu()
    {
        Option option = Option.Unknown;
        Scanner s = getScanner();
        try
        {
            // DO NOT CHANGE ANYTHING!
            System.out.println("  ___ ___                 ");
            System.out.println(" | __| _ \\__ _ _  _ ___  ");
            System.out.println(" | _||  _/ _` | || (_-<  ");
            System.out.println(" |___|_| \\__,_|\\_,_/__/  ");
            System.out.println("        Management DEMO   ");
            System.out.println();
            System.out.println("1. Exit");
            System.out.println("2. Create Client");
            System.out.println("3. Create Portefolio");
            System.out.println("4. List Positions");
            System.out.println("5. Update Investments");
            System.out.println("6. Update Client");
            System.out.println("7. About");
            System.out.print(">");
            int result = s.nextInt();
            option = Option.values()[result];
        }
        catch(RuntimeException ex)
        {
            //nothing to do.
        }
        
        return option;

    }
    private static void clearConsole() throws Exception
    {
        // DO NOT CHANGE ANYTHING!
        for (int y = 0; y < 25; y++) //console is 80 columns and 25 lines
            System.out.println("\n");
    }

    public void Run() throws Exception
    {
        // DO NOT CHANGE ANYTHING!
        Option userInput;
        do
        {
            clearConsole();
            userInput = DisplayMenu();
            clearConsole();
            try
            {
                __dbMethods.get(userInput).doWork();
                System.in.read();
            }
            catch(NullPointerException ex)
            {
                //Nothing to do. The option was not a valid one. Read another.
            }

        }while(userInput!=Option.Exit);
    }

    /**
    To implement from this point forward. 
    -------------------------------------------------------------------------------------     
        IMPORTANT:
    --- DO NOT MESS WITH THE CODE ABOVE. YOU JUST HAVE TO IMPLEMENT THE METHODS BELOW ---
    --- Other Methods and properties can be added to support implementation. 
    ---- Do that also below                                                         -----
    -------------------------------------------------------------------------------------
    
    */


    //Implement an AutoClosable object. 
    // If needed you can add more stuff to clean at the end
    @Override
    public void close()
    {
        if(__s != null)
        {
            __s.close();
            __s = null;
        }
    }

    private void createClient() {
        Scanner s = getScanner();
        try (Dal dal = new Dal()) {
            System.out.print("NIF: ");
            String nif = readRequiredLine(s);
            System.out.print("Cartao de cidadao: ");
            String citizenCard = readRequiredLine(s);
            System.out.print("Nome: ");
            String name = readRequiredLine(s);
            System.out.print("Tipo de contacto (email/telefone): ");
            String contactType = readRequiredLine(s);
            System.out.print("Contacto: ");
            String contact = readRequiredLine(s);
            System.out.print("Descricao do contacto: ");
            String description = readRequiredLine(s);

            dal.createClientWithContact(nif, citizenCard, name, contactType, contact, description);
            System.out.println("Cliente criado com sucesso.");
        } catch (Exception ex) {
            System.out.println("Erro ao criar cliente: " + ex.getMessage());
        }
    }
  
    private void createPortfolio()
    {
        Scanner s = getScanner();
        try (Dal dal = new Dal()) {
            System.out.print("NIF do cliente: ");
            String nif = readRequiredLine(s);
            System.out.print("Nome do portefolio: ");
            String name = readRequiredLine(s);

            dal.createPortfolio(nif, name);
            System.out.println("Portefolio criado com sucesso.");
        } catch (Exception ex) {
            System.out.println("Erro ao criar portefolio: " + ex.getMessage());
        }
    }

    private void listPositions()
    {
        Scanner s = getScanner();
        try (Dal dal = new Dal()) {
            System.out.print("NIF do cliente: ");
            String nif = readRequiredLine(s);
            List<Dal.PositionRow> positions = dal.listPositionsByClient(nif);

            if (positions.isEmpty()) {
                System.out.println("Nao existem posicoes para o cliente indicado.");
                return;
            }

            long currentPortfolio = -1;
            for (Dal.PositionRow row : positions) {
                if (row.portfolioId() != currentPortfolio) {
                    currentPortfolio = row.portfolioId();
                    System.out.printf("%nPortefolio %d - %s | Total: %.2f%n",
                            row.portfolioId(), row.portfolioName(), row.portfolioTotal());
                    System.out.println("ISIN         | Quantidade | Valor actual | Valor posicao | Var. diaria");
                }
                System.out.printf("%-12s | %10.4f | %12.2f | %13.2f | %10.2f%%%n",
                        row.isin(), row.quantity(), row.currentValue(), row.positionTotal(),
                        row.dailyVariationPercent());
            }
        } catch (Exception ex) {
            System.out.println("Erro ao listar posicoes: " + ex.getMessage());
        }

    }

    private void updateInvestments() {
        try (Dal dal = new Dal()) {
            dal.updateDailyValues();
            System.out.println("Valores diarios actualizados com sucesso.");
        } catch (Exception ex) {
            System.out.println("Erro ao actualizar valores diarios: " + ex.getMessage());
        }
    }

    private void updateClient()
    {
        Scanner s = getScanner();
        try (Dal dal = new Dal()) {
            System.out.print("NIF do cliente: ");
            String nif = readRequiredLine(s);
            Cliente cliente = dal.findClient(nif);
            if (cliente == null) {
                System.out.println("Cliente inexistente.");
                return;
            }

            System.out.printf("Nome actual [%s]: ", cliente.getNome());
            String name = readOptionalLine(s);
            System.out.printf("Cartao de cidadao actual [%s]: ", cliente.getCartaoCidadao());
            String citizenCard = readOptionalLine(s);

            if (name.isBlank()) {
                name = cliente.getNome();
            }
            if (citizenCard.isBlank()) {
                citizenCard = cliente.getCartaoCidadao();
            }

            dal.updateClient(nif, citizenCard, name);
            System.out.println("Cliente actualizado com sucesso.");
        } catch (IllegalStateException ex) {
            System.out.println(ex.getMessage());
        } catch (Exception ex) {
            System.out.println("Erro ao actualizar cliente: " + ex.getMessage());
        }
        
    }

    private void about()
    {
        // TODO: Change the code and your Group ID & member names
        System.out.println("Brought to you by a wonderful set of professors!");
        System.out.println("DAL version:"+ isel.sisinf.jpa.Dal.version());
        System.out.println("Core version:"+ isel.sisinf.model.Core.version());
        
    }

    private String readRequiredLine(Scanner scanner) {
        String value = scanner.nextLine();
        while (value.isEmpty()) {
            value = scanner.nextLine();
        }
        return value.trim();
    }

    private String readOptionalLine(Scanner scanner) {
        return scanner.nextLine().trim();
    }
}

public class App{
    public static void main(String[] args) throws Exception{
       try(UI ui = UI.getInstance())
        {
            ui.Run();
        }
    }
}
