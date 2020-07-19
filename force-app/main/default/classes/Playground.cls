public class Playground {

    public class AccountComposer implements DatabaseMonad.Composer {

        public SObject compose(Map<String, SObject> input) {

            Lead lead = (Lead) input.get('Lead');
            Account account = new Account(Name = lead.Company);

            return account;
        }

        public String getType() {
            return 'Account';
        }
    }

    public class ContactComposer implements DatabaseMonad.Composer {

        public SObject compose(Map<String, SObject> input) {

            Lead lead = (Lead) input.get('Lead');
            Account account = (Account) input.get('Account');
            Contact contact = new Contact(
                Lastname = lead.Lastname,
                AccountId = account.Id
            );

            return contact;
        }

        public String getType() {
            return 'Contact';
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
