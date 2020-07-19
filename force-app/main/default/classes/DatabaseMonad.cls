public class DatabaseMonad {

    public class Bundle {

        public Map<String, SObject> contents = new Map<String, SObject>();
        public String error;

        public Bundle(SObject sobj) {
            this.add(sobj);
        }

        public void add(SObject sobj) {
            this.contents.put(String.valueOf(sobj.getSObjectType()), sobj);
        }

        public SObject get(String sobjectType) {
            return contents.get(sobjectType);
        }
    }

    private List<Bundle> bundles = new List<Bundle>();

    public interface Composer {
        List<SObject> compose(List<Map<String, SObject>> input);
    }

    // this is the unit function in terms of the Monad pattern
    public DatabaseMonad(List<SObject> items) {
        for (SObject item : items) {
            this.bundles.add(new Bundle(item));
        }
    }

    public DatabaseMonad insertSObjects(Composer composer) {

        List<Bundle> readyForProcessing = DatabaseMonad.excludeFailed(bundles);

        List<SObject> sobjectsToInsert = composer.compose(DatabaseMonad.extract(readyForProcessing));
        List<Database.SaveResult> results = Database.insert(sobjectsToInsert, false);

        for (Integer i=0; i<results.size(); i++) {

            if (results[i].isSuccess() != true) {
                readyForProcessing[i].error = String.valueOf(results[i].getErrors());
                continue;
            }

            readyForProcessing[i].add(sobjectsToInsert[i]);
        }

        return this;
    }

    @testVisible
    private static List<Map<String, SObject>> extract(List<Bundle> bundles) {

        List<Map<String, SObject>> result = new List<Map<String, SObject>>();

        for (Bundle bundle : bundles) {
            result.add(bundle.contents);
        }

        return result;
    }

    @testVisible
    private static List<Bundle> excludeFailed(List<Bundle> input) {
        List<Bundle> output = new List<Bundle>();
        for (Bundle bundle : input) {
            if (String.isBlank(bundle.error)) output.add(bundle);
        }
        return output;
    }

}
