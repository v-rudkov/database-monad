public class DatabaseMonad {

    public class Bundle {

        public Map<String, Object> contents = new Map<String, Object>();
        public String error;

        public Bundle(Map<String, Object> pairs) {
            this.add(pairs);
        }

        public Bundle(SObject sobj) {
            this.add(sobj);
        }

        public void add(Map<String, Object> pairs) {
            for (String key : pairs.keySet()) {
                this.contents.put(key, pairs.get(key));
            }
        }

        public void add(SObject sobj) {
            this.contents.put(String.valueOf(sobj.getSObjectType()), sobj);
        }

        public Object get(String key) {
            return contents.get(key);
        }

        public Boolean isFailed() {
            return String.isNotBlank(this.error);
        }
    }

    private List<Bundle> bundles = new List<Bundle>();

    public interface Composer {
        Object newValue(Map<String, Object> input);
        String getKey();
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
                bundle.add(new Map<String, Object>{
                    composer.getKey() => composer.newValue(bundle.contents)
                });
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
        List<SObject> sobjectsToInsert = (List<SObject>) DatabaseMonad.extractObjects(
            List<SObject>.class,
            composer.getKey(),
            successfulBundles
        );

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
    private static List<Object> extractObjects(Type objectType, String key, List<Bundle> input) {
        List<Object> result = (List<Object>)objectType.newInstance();
        for (Bundle bundle : input) {
            if (bundle.isFailed()) continue;
            result.add(bundle.get(key));
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
