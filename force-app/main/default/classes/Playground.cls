public class Playground {

    public class AccountComposer implements DatabaseMonad.Composer {

        public List<SObject> compose(List<Map<String, SObject>> input) {

            List<Account> accounts = new List<Account>();

            for (Map<String, SObject> item : input) {
                Lead lead = (Lead) item.get('Lead');
                accounts.add(new Account(Name = lead.Company));
            }

            return accounts;
        }
    }

    public class ContactComposer implements DatabaseMonad.Composer {

        public List<SObject> compose(List<Map<String, SObject>> input) {

            List<Contact> contacts = new List<Contact>();

            for (Map<String, SObject> item : input) {
                Lead lead = (Lead) item.get('Lead');
                Account account = (Account) item.get('Account');
                contacts.add(new Contact(
                    Lastname = lead.Lastname,
                    AccountId = account.Id
                ));
            }

            return contacts;
        }
    }

    public static void main() {

        List<Lead> leads = [select Id, Lastname, Company from Lead where IsConverted = false];

        /*
        new DatabaseMonad(leads)
            .insertSObjects(new AccountPerformer())
            .insertSObjects(new ContactPerformer())
            .performConvert(convertLeads)
            .handleErrors()
            .returnValues();
        */    
        new DatabaseMonad(leads)
            .insertSObjects(new AccountComposer())
            .insertSObjects(new ContactComposer());
    }

}
