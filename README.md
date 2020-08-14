# Inspired by the Monad

Let say we need to implement a method that will take a list of leads and will convert them into new accounts and contacts.
And because we need a particular record types for accounts and contacts, we need to create them first and convert the leads
into newly created accouns and contacts. So what might an approach to implement this scenario look like? And how fault tolerant
will it be? (Does it support partial success? How are the potential exceptions going to be processed?)

### Simple straightforward approach:

```
    System.Savepoint serviceSavePoint = Database.setSavePoint();
    try {
        List<Lead> leads = [select ... from Lead where ...];

        for (Lead lead : leads) {
            Accounts.add(new Account(Name = lead.Company));
        }
        insert accounts;

        for (Integer i=0; i<leads.size(); i++) {
            Contacts.add(new Contact(Lastname = leads[i].Lastname, AccountId = accounts[i].Id);
        }

        for (Integer i=0; i<leads.size(); i++) {
            LeadConvert leadConvert = new LeadConvert();
            // ...
            leadConverts.add(leadConvert);
        }

        Database.convertLead(leadConverts);
    }

    catch (Exception ex) {
        Database.rollback(serviceSavePoint);
        throw ex;
    }
```
### Unit of Work

The implementation leveraging fflib Unit of Work doesn't look more readable, and it doesn't provide
somewhat higher fault tolerance - it is still the same all or none behavior:

```
    fflib_ISObjectUnitOfWork unitOfWork = Application.UnitOfWork.newInstance();

    List<Lead> leads = [select ... from Lead where ...];

    for (Lead lead : leads) {

        Account account = new Account(Name = lead.Company));
        unitOfWork.registerNew(account);

        Contact con = new Contact(
            Lastname = leads[0].Lastname,
        );
        unitOfWork.registerNew(con, Contact.AccountId, account);

        Database.LeadConvert leadConvert = new Database.LeadConvert();
        // ...

        unitOfWork.registerLeadConvert(leadConvert);    // pseudo code, as fflib doesn't support this
    }

    unitOfWork.commitWork();
```

### "Monad" approach

It's hard to implement a true monad in apex, as it doesn't support passing functions as paremeters.

```
        List<Lead> leads = [select ... from Lead where ...];

        return new DatabaseMonad(leads)
            .insertSObjects(new AccountComposer())
            .insertSObjects(new ContactComposer())
            .convertLeads(new LeadConvertComposer())
            .handleErrors()
            .getContents();



    public class AccountComposer implements DatabaseMonad.Composer {

        public Object newValue(Map<String, Object> input) {
            Lead lead = (Lead) input.get('Lead');
            return new Account(Name = lead.Company);
        }

        public String getKey() {
            return 'Account';
        }
    }

    public class ContactComposer implements DatabaseMonad.Composer {

        public Object newValue(Map<String, Object> input) {
            Lead lead = (Lead) input.get('Lead');
            Account account = (Account) input.get('Account');
            return new Contact(Lastname = lead.Lastname, AccountId = account.Id);
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
            leadConvert.setAccountId(account.Id);
            leadConvert.setContactId(contact.Id);
            // ...

            return leadConvert;
        }

        public String getKey() {
            return 'LeadConvert';
        }
    }

```

```
    public class Bundle {

        public Map<String, Object> contents = new Map<String, Object>();
        public String error;
    }
```

![Bundles](/img/Bundles.png)

