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

        public Boolean isFailed() {
            return String.isNotBlank(this.error);
        }
    }

    private List<Bundle> bundles = new List<Bundle>();

    public interface Composer {
        SObject compose(Map<String, SObject> input);
        String getType();
    }

    // this is the unit function in terms of the Monad pattern
    public DatabaseMonad(List<SObject> items) {
        for (SObject item : items) {
            this.bundles.add(new Bundle(item));
        }
    }

    public DatabaseMonad insertSObjects(Composer composer) {

        this.bundles = DatabaseMonad.composeSObjects(composer, this.bundles);
        this.bundles = DatabaseMonad.insertSObjects(composer, this.bundles);

        return this;
    }

    @testVisible
    private static List<Bundle> composeSObjects(Composer composer, List<Bundle> bundles) {

        for (Bundle bundle : bundles) {

            if (bundle.isFailed()) continue;

            try {
                bundle.add(composer.compose(bundle.contents));
            }

            catch (Exception ex) {
                bundle.error = ex.getMessage() + ' ' + ex.getStackTraceString();
            }

        }

        return bundles;
    }

    @testVisible
    private static List<Bundle> insertSObjects(Composer composer, List<Bundle> bundles) {

        List<Bundle> successfulBundles = DatabaseMonad.excludeFailed(bundles);
        List<SObject> sobjectsToInsert = DatabaseMonad.extractSObjects(composer.getType(), successfulBundles);

        List<Database.SaveResult> results = Database.insert(sobjectsToInsert, false);

        for (Integer i=0; i<results.size(); i++) {

            if (results[i].isSuccess() != true) {
                successfulBundles[i].error = String.valueOf(results[i].getErrors());
                continue;
            }

            successfulBundles[i].add(sobjectsToInsert[i]);
        }

        return bundles;
    }

    @testVisible
    private static List<SObject> extractSObjects(String type, List<Bundle> input) {
        List<SObject> result = new List<SObject>();
        for (Bundle bundle : input) {
            if (bundle.isFailed()) continue;
            result.add(bundle.get(type));
        }
        return result;
    }

    @testVisible
    private static List<Bundle> excludeFailed(List<Bundle> input) {
        List<Bundle> result = new List<Bundle>();
        for (Bundle bundle : input) {
            if (!bundle.isFailed()) result.add(bundle);
        }
        return result;
    }

}
