public class Playground {

    public class AccountComposer implements DatabaseMonad.Composer {

        public Object newValue(Map<String, Object> input) {

            Lead lead = (Lead) input.get('Lead');
            Account account = new Account(Name = lead.Company);

            return account;
        }

        public String getKey() {
            return 'Account';
        }
    }

    public class ContactComposer implements DatabaseMonad.Composer {

        public Object newValue(Map<String, Object> input) {

            Lead lead = (Lead) input.get('Lead');
            Account account = (Account) input.get('Account');
            Contact contact = new Contact(
                Lastname = lead.Lastname,
                AccountId = account.Id
            );

            return contact;
        }

        public String getKey() {
            return 'Contact';
        }
    }

    public class LeadConvertComposer implements DatabaseMonad.Composer {

        public Object newValue(Map<String, Object> input) {

            Lead lead = (Lead) input.get('Lead');
            Account account = (Account) input.get('Account');
            Contact contact = (Contact) input.get('Contact');

            Database.LeadConvert leadConvert = new Database.LeadConvert();
            leadConvert.setLeadId(lead.Id);
            leadConvert.setConvertedStatus([select MasterLabel from LeadStatus where IsConverted=true][0].MasterLabel);
            leadConvert.setDoNotCreateOpportunity(true);
            leadConvert.setAccountId(account.Id);
            leadConvert.setContactId(contact.Id);

            return leadConvert;
        }

        public String getKey() {
            return 'LeadConvert';
        }
    }

    public static Object main() {

        List<Lead> leads = [select Id, Lastname, Company from Lead where IsConverted = false];

        return new DatabaseMonad(leads)
            .insertSObjects(new AccountComposer())
            .insertSObjects(new ContactComposer())
            .convertLeads(new LeadConvertComposer())
            .getContents();
    }

}
