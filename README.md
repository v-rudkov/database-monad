# Monad Design Pattern

Let say we need to implement a method that will take a list of leads and will convert them into new accounts and contacts.
And becase we need a particular record types for accounts and contacts we need to create them first and convert the leads
into newly created accouns and contacts. So what might an approach to implement this scenario look like? And how fauld tolerant
will it be? (Does it supports partial success? How are the potential exceptions going to be processed?)

### Simple straightforward approach:

```
    System.Savepoint serviceSavePoint = Database.setSavePoint();
    try {
        List<Lead> leads = new List<Lead>();

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

    List<Lead> leads = new List<Lead>();
    List<Account> accounts

    for (Lead lead : leads) {

        Account account = new Account(Name = lead.Company));
        unitOfWork.registerNew(account);

        Contact con = new Contact(
            Lastname = leads[0].Lastname,
        );
        unitOfWork.registerNew(con, Contact.AccountId, account);

        // pseudo code, as fflib doesn't support this
        Database.LeadConvert leadConvert = new Database.LeadConvert();
        // ...
        unitOfWork.registerLeadConvert(leadConvert);
    }

    unitOfWork.commitWork();
```
### "Monad" approach

```
    public class Bundle {

        public Map<String, Object> contents = new Map<String, Object>();
        public String error;
    }
```
