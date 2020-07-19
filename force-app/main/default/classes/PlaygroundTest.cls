@isTest
public class PlaygroundTest {

    @isTest static void test_1() {
        // given 
        Lead lead = new Lead(Lastname = 'TestLead', Company = 'Acme');
        insert lead;

        // when
        Playground.main();

        // then
        List<Account> accounts = [select Id, Name from Account];
        List<Contact> contacts = [select Id, AccountId, Lastname from Contact];

        System.assertEquals(1, accounts.size());
        System.assertEquals(lead.Company, accounts[0].Name);

        System.assertEquals(1, contacts.size());
        System.assertEquals(lead.Lastname, contacts[0].Lastname);
    }
}
