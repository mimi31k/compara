
# Release Coordinator, please update this file before starting every release
# and check the changes back into CVS for everyone's benefit.

# Things that normally need updating are:
#
# 1. Release number
# 2. Check the name prefix of all databases
# 3. Possibly add entries for core databases that are still on genebuilders' servers

use strict;
use Bio::EnsEMBL::Utils::ConfigRegistry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Compara::DBSQL::DBAdaptor;


# The majority of core databases live on two staging servers:

Bio::EnsEMBL::Registry->load_registry_from_url(
  'mysql://ensro@ens-staging1/70');

Bio::EnsEMBL::Registry->load_registry_from_url(
  'mysql://ensro@ens-staging2/70');


# Extra core databases that live on genebuilders' servers:

#Bio::EnsEMBL::DBSQL::DBAdaptor->new(
#    -host => 'genebuild1',
#    -user => 'ensro',
#    -port => 3306,
#    -species => 'gorilla_gorilla',
#    -group => 'core',
#    -dbname => 'ba1_gorilla31_new',
#);


# Compara databases used during the release (master, previous and current compara dbs)

# Master
Bio::EnsEMBL::Compara::DBSQL::DBAdaptor->new(
    -host => 'compara1',
    -user => 'ensadmin',
    -pass => $ENV{'ENSADMIN_PSW'},
    -port => 3306,
    -species => 'compara_master',
    -dbname => 'sf5_ensembl_compara_master',
);

# Prev release
Bio::EnsEMBL::Compara::DBSQL::DBAdaptor->new(
    -host => 'compara3',
    -user => 'ensadmin',
    -pass => $ENV{'ENSADMIN_PSW'},
    -port => 3306,
    -species => 'compara_prev',
    -dbname => 'sf5_ensembl_compara_69',
);

# Curr
Bio::EnsEMBL::Compara::DBSQL::DBAdaptor->new(
    -host => 'compara3',
    -user => 'ensadmin',
    -pass => $ENV{'ENSADMIN_PSW'},
    -port => 3306,
    -species => 'compara_curr',
    -dbname => 'sf5_ensembl_compara_70',
);

Bio::EnsEMBL::Compara::DBSQL::DBAdaptor->new( ## TO BE FIXED BEFORE HOMOLOGY MERGE
    -host => 'compara1',
    -user => 'ensadmin',
    -pass => $ENV{'ENSADMIN_PSW'},
    -port => 3306,
    -species => 'compara_homology_merged',
    -dbname => 'mm14_compara_homology_merged_69',
);

Bio::EnsEMBL::Compara::DBSQL::DBAdaptor->new( ## HAS TO BE CREATED (FINAL DB)
    -host => 'ens-staging',
    -user => 'ensadmin',
    -pass => $ENV{'ENSADMIN_PSW'},
    -port => 3306,
    -species => 'compara_staging',
    -dbname => 'ensembl_compara_70',
);

1;
