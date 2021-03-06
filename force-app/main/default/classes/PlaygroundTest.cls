@isTest
public class PlaygroundTest {

    @isTest static void test_1() {
        // given 
        Lead lead = new Lead(Lastname = 'TestLead', Company = 'Acme');
        insert lead;

        // when
        List<DatabaseMonad.Bundle> result = (List<DatabaseMonad.Bundle>) Playground.main();

        // then
        List<Lead> leads = [select Id, IsConverted, ConvertedAccountId, ConvertedContactId from Lead];
        List<Account> accounts = [select Id, Name from Account];
        List<Contact> contacts = [select Id, AccountId, Lastname from Contact];

        System.assertEquals(1, accounts.size());
        System.assertEquals(lead.Company, accounts[0].Name);

        System.assertEquals(1, contacts.size());
        System.assertEquals(lead.Lastname, contacts[0].Lastname);

        System.assertEquals(1, leads.size());
        System.assertEquals(true, leads[0].IsConverted);
        System.assertEquals(accounts[0].Id, leads[0].ConvertedAccountId);
        System.assertEquals(contacts[0].Id, leads[0].ConvertedContactId);
    }
}
