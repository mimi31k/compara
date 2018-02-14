# conventions taken from the new clean schema of EnsEMBL
# use lower case and underscores
# internal ids are integers named tablename_id
# same name is given in foreign key relations


# --------------------------------- common part of the schema ------------------------------------

#
# Table structure for table 'meta'
#
# This table stores meta information about the compara database
#

CREATE TABLE IF NOT EXISTS meta (

  meta_id                     INT NOT NULL AUTO_INCREMENT,
  species_id                  INT UNSIGNED DEFAULT 1,
  meta_key                    VARCHAR(40) NOT NULL,
  meta_value                  TEXT NOT NULL,

  PRIMARY   KEY (meta_id),
  UNIQUE    KEY species_key_value_idx (species_id, meta_key, meta_value(255)),
            KEY species_value_idx (species_id, meta_value(255))

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



#
# Table structure for tables 'ncbi_taxa_node' and 'ncbi_taxa_name'
#
# Contains all taxa used in this database, which mirror the data and tree structure
# from NCBI Taxonomy database (for more details see ensembl-compara/script/taxonomy/README-taxonomy
# which explain our import process)
#

CREATE TABLE ncbi_taxa_node (
  taxon_id                        int(10) unsigned NOT NULL,
  parent_id                       int(10) unsigned NOT NULL,

  rank                            char(32) default '' NOT NULL,
  genbank_hidden_flag             tinyint(1) default 0 NOT NULL,

  left_index                      int(10) DEFAULT 0 NOT NULL,
  right_index                     int(10) DEFAULT 0 NOT NULL,
  root_id                         int(10) default 1 NOT NULL,

  PRIMARY KEY (taxon_id),
  KEY (parent_id),
  KEY (rank),
  KEY (left_index),
  KEY (right_index)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;

CREATE TABLE ncbi_taxa_name (
  taxon_id                    int(10) unsigned NOT NULL,

  name                        varchar(255),
  name_class                  varchar(50),

  FOREIGN KEY (taxon_id) REFERENCES ncbi_taxa_node(taxon_id),

  KEY (taxon_id),
  KEY (name),
  KEY (name_class)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'genome_db'
#
# Contains information about the version of the genome assemblies used in this database
#

CREATE TABLE genome_db (
  genome_db_id                int(10) unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  taxon_id                    int(10) unsigned DEFAULT NULL, # KF taxon.taxon_id
  name                        varchar(40) DEFAULT '' NOT NULL,
  assembly                    varchar(100) DEFAULT '' NOT NULL,
  assembly_default            tinyint(1) DEFAULT 1,
  genebuild                   varchar(100) DEFAULT '' NOT NULL,
  locator                     varchar(400),

  FOREIGN KEY (taxon_id) REFERENCES ncbi_taxa_node(taxon_id),

  PRIMARY KEY (genome_db_id),
  UNIQUE name (name,assembly,genebuild)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'species_set'
#
# Each species_set is a set of genome_db objects
#

CREATE TABLE species_set (
  species_set_id              int(10) unsigned NOT NULL AUTO_INCREMENT,
  genome_db_id                int(10) unsigned DEFAULT NULL,

  FOREIGN KEY (genome_db_id) REFERENCES genome_db(genome_db_id),

  UNIQUE KEY  (species_set_id,genome_db_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'species_set_tag'
#
# This table is used to store options on clades and group of species. It
# has been initially developed for the gene tree view.
#

CREATE TABLE species_set_tag (
  species_set_id              int(10) unsigned NOT NULL, # FK species_set.species_set_id
  tag                         varchar(50) NOT NULL,
  value                       mediumtext,

  ## NB: species_set_id is not unique so cannot be used as a foreign key
  # FOREIGN KEY (species_set_id) REFERENCES species_set(species_set_id),

  UNIQUE KEY tag_species_set_id (species_set_id,tag)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'method_link'
#
# Specifies which kind of link can exist between species
# (dna/dna alignment, synteny regions, homologous gene pairs,...)
#

CREATE TABLE method_link (
  method_link_id              int(10) unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  type                        varchar(50) DEFAULT '' NOT NULL,
  class                       varchar(50) DEFAULT '' NOT NULL,

  PRIMARY KEY (method_link_id),
  UNIQUE KEY type (type)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'method_link_species_set'
#

CREATE TABLE method_link_species_set (
  method_link_species_set_id  int(10) unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  method_link_id              int(10) unsigned, # FK method_link.method_link_id
  species_set_id              int(10) unsigned NOT NULL default 0,
  name                        varchar(255) NOT NULL default '',
  source                      varchar(255) NOT NULL default 'ensembl',
  url                         varchar(255) NOT NULL default '',

  FOREIGN KEY (method_link_id) REFERENCES method_link(method_link_id),
  ## NB: species_set_id is not unique so cannot be used as a foreign key
  # FOREIGN KEY (species_set_id) REFERENCES species_set(species_set_id),

  PRIMARY KEY (method_link_species_set_id),
  UNIQUE KEY method_link_id (method_link_id,species_set_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'method_link_species_set_tag'
#

CREATE TABLE method_link_species_set_tag (
  method_link_species_set_id  int(10) unsigned NOT NULL, # FK species_set.species_set_id
  tag                         varchar(50) NOT NULL,
  value                       mediumtext,

  FOREIGN KEY (method_link_species_set_id) REFERENCES method_link_species_set(method_link_species_set_id),

  PRIMARY KEY tag_mlss_id (method_link_species_set_id,tag)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


# --------------------------------- DNA part of the schema ------------------------------------

#
# Table structure for table 'synteny_region'
#
# We have now decided that Synteny is inherently pairwise
# these tables hold the pairwise information for the synteny
# regions. We reuse the dnafrag table as a link out for identifiers
# (eg, '2' on mouse).
#

CREATE TABLE synteny_region (
  synteny_region_id           int(10) unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  method_link_species_set_id  int(10) unsigned NOT NULL, # FK method_link_species_set.method_link_species_set_id

  FOREIGN KEY (method_link_species_set_id) REFERENCES method_link_species_set(method_link_species_set_id),

  PRIMARY KEY (synteny_region_id),
  KEY (method_link_species_set_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'dnafrag'
#
-- Index <name> has genome_db_id in the first place because unless fetching all danfrags
--   or fetching by dnafrag_id, genome_db_id appears always in the WHERE clause
-- Unique key <name> is used to ensure that
--   Bio::EnsEMBL::Compara::DBSQL::DnaFragAdaptor->fetch_by_GenomeDB_and_name
--   will always fetch a single row. This can be used in the EnsEMBL Compara DB
--   because we store top-level dnafrags only.

CREATE TABLE dnafrag (
  dnafrag_id                  bigint unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  length                      int(11) DEFAULT 0 NOT NULL,
  name                        varchar(40) DEFAULT '' NOT NULL,
  genome_db_id                int(10) unsigned NOT NULL, # FK genome_db.genome_db_id
  coord_system_name           varchar(40) DEFAULT NULL,
  is_reference                tinyint(1) DEFAULT 1,

  FOREIGN KEY (genome_db_id) REFERENCES genome_db(genome_db_id),

  PRIMARY KEY (dnafrag_id),
  UNIQUE name (genome_db_id, name)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'dnafrag_region'
#

CREATE TABLE dnafrag_region (
  synteny_region_id           int(10) unsigned DEFAULT 0 NOT NULL, # unique internal id
  dnafrag_id                  bigint unsigned DEFAULT 0 NOT NULL, # FK dnafrag.dnafrag_id
  dnafrag_start               int(10) unsigned DEFAULT 0 NOT NULL,
  dnafrag_end                 int(10) unsigned DEFAULT 0 NOT NULL,
  dnafrag_strand              tinyint(4) DEFAULT 0 NOT NULL,

  FOREIGN KEY (synteny_region_id) REFERENCES synteny_region(synteny_region_id),
  FOREIGN KEY (dnafrag_id) REFERENCES dnafrag(dnafrag_id),

  KEY synteny (synteny_region_id,dnafrag_id),
  KEY synteny_reversed (dnafrag_id,synteny_region_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'genomic_align_block'
#
#    This table indexes the genomic alignments
#
-- All queries in the API uses the primary key as rows are always fetched using
--   the genomic_align_block_id. The key 'method_link_species_set_id' is used by
--   MART when fetching all the genomic_align_blocks corresponding to a given
--   method_link_species_set_id.z

CREATE TABLE genomic_align_block (
  genomic_align_block_id      bigint unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  method_link_species_set_id  int(10) unsigned DEFAULT 0 NOT NULL, # FK method_link_species_set_id.method_link_species_set_id
  score                       double,
  perc_id                     tinyint(3) unsigned DEFAULT NULL,
  length                      int(10),
  group_id                    bigint unsigned DEFAULT NULL,
  level_id                    tinyint(2) unsigned DEFAULT 0 NOT NULL,

  FOREIGN KEY (method_link_species_set_id) REFERENCES method_link_species_set(method_link_species_set_id),

  PRIMARY KEY genomic_align_block_id (genomic_align_block_id),
  KEY method_link_species_set_id (method_link_species_set_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;

#
# Table structure for table 'genomic_align_tree'
#
#   This table stores the phylogenetic relationship between different genomic_align entries.
#   This is required to store the tree alignments, i.e. multiple sequence alignments with
#   ancestral sequence reconstruction. This table stores the tree underlying each tree
#   alignments
#
-- primary key is a foreign key to genomic_align.node_id

CREATE TABLE genomic_align_tree (
  node_id                     bigint(20) unsigned NOT NULL AUTO_INCREMENT, # internal id, FK genomic_align.node_id
  parent_id                   bigint(20) unsigned NOT NULL default 0,
  root_id                     bigint(20) unsigned NOT NULL default 0,
  left_index                  int(10) NOT NULL default 0,
  right_index                 int(10) NOT NULL default 0,
  left_node_id                bigint(10) NOT NULL default 0,
  right_node_id               bigint(10) NOT NULL default 0,
  distance_to_parent          double NOT NULL default 1,

  PRIMARY KEY node_id (node_id),
  KEY parent_id (parent_id),
  KEY root_id (root_id),
  KEY left_index (root_id, left_index)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;

#
# Table structure for table 'genomic_align'
#
#   This table stores the sequences belonging to the same genomic_align_block entry
#
-- primary key is used when fetching by dbID
-- key genomic_align_block_id is used when fetching by genomic_align_block_id
-- key dnafrag is used in all other queries

CREATE TABLE genomic_align (
  genomic_align_id            bigint unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  genomic_align_block_id      bigint unsigned NOT NULL, # FK genomic_align_block.genomic_align_block_id
  method_link_species_set_id  int(10) unsigned DEFAULT 0 NOT NULL, # FK method_link_species_set_id.method_link_species_set_id
  dnafrag_id                  bigint unsigned DEFAULT 0 NOT NULL, # FK dnafrag.dnafrag_id
  dnafrag_start               int(10) DEFAULT 0 NOT NULL,
  dnafrag_end                 int(10) DEFAULT 0 NOT NULL,
  dnafrag_strand              tinyint(4) DEFAULT 0 NOT NULL,
  cigar_line                  mediumtext,
  visible                     tinyint(2) unsigned DEFAULT 1 NOT NULL,
  node_id                     bigint(20) unsigned DEFAULT NULL,

  FOREIGN KEY (genomic_align_block_id) REFERENCES genomic_align_block(genomic_align_block_id),
  FOREIGN KEY (method_link_species_set_id) REFERENCES method_link_species_set(method_link_species_set_id),
  FOREIGN KEY (dnafrag_id) REFERENCES dnafrag(dnafrag_id),
  FOREIGN KEY (node_id) REFERENCES genomic_align_tree(node_id),

  PRIMARY KEY genomic_align_id (genomic_align_id),
  KEY genomic_align_block_id (genomic_align_block_id),
  KEY method_link_species_set_id (method_link_species_set_id),
  KEY dnafrag (dnafrag_id, method_link_species_set_id, dnafrag_start, dnafrag_end),
  KEY node_id (node_id)
) MAX_ROWS = 1000000000 AVG_ROW_LENGTH = 60 COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'conservation_score'
#

CREATE TABLE conservation_score (
  genomic_align_block_id bigint unsigned not null,
  window_size            smallint unsigned not null,
  position               int unsigned not null,
  expected_score         blob,
  diff_score             blob,

  FOREIGN KEY (genomic_align_block_id) REFERENCES genomic_align_block(genomic_align_block_id),

  KEY (genomic_align_block_id, window_size)
) MAX_ROWS = 15000000 AVG_ROW_LENGTH = 841 COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'constrained_element'
#

CREATE TABLE constrained_element (
  constrained_element_id bigint(20) unsigned NOT NULL,
  dnafrag_id bigint unsigned NOT NULL,
  dnafrag_start int(12) unsigned NOT NULL,
  dnafrag_end int(12) unsigned NOT NULL,
  dnafrag_strand int(2),
  method_link_species_set_id int(10) unsigned NOT NULL,
  p_value double,
  score double NOT NULL default 0,

  FOREIGN KEY (dnafrag_id) REFERENCES dnafrag(dnafrag_id),
  FOREIGN KEY (method_link_species_set_id) REFERENCES method_link_species_set(method_link_species_set_id),

  KEY constrained_element_id_idx (constrained_element_id),
  KEY mlssid_idx (method_link_species_set_id),
  KEY mlssid_dfId_dfStart_dfEnd_idx (method_link_species_set_id,dnafrag_id,dnafrag_start,dnafrag_end),
  KEY mlssid_dfId_idx (method_link_species_set_id,dnafrag_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


# --------------------------------- Protein part of the schema ------------------------------------

#
# Table structure for table 'sequence'
#

CREATE TABLE sequence (
  sequence_id                 int(10) unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  length                      int(10) NOT NULL,
  sequence                    longtext NOT NULL,

  PRIMARY KEY (sequence_id),
  KEY sequence (sequence(18))
) MAX_ROWS = 10000000 AVG_ROW_LENGTH = 19000 COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'member'
#

CREATE TABLE member (
  member_id                   int(10) unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  stable_id                   varchar(128) NOT NULL, # e.g. ENSP000001234 or P31946
  version                     int(10) DEFAULT 0,
  source_name                 ENUM('ENSEMBLGENE','ENSEMBLPEP','Uniprot/SPTREMBL','Uniprot/SWISSPROT','ENSEMBLTRANS','EXTERNALCDS') NOT NULL,
  taxon_id                    int(10) unsigned NOT NULL, # FK taxon.taxon_id
  genome_db_id                int(10) unsigned, # FK genome_db.genome_db_id
  sequence_id                 int(10) unsigned, # FK sequence.sequence_id
  gene_member_id              int(10) unsigned, # FK member.member_id
  canonical_member_id         int(10) unsigned, # FK member.member_id
  description                 text DEFAULT NULL,
  chr_name                    char(40),
  chr_start                   int(10),
  chr_end                     int(10),
  chr_strand                  tinyint(1) NOT NULL,
  display_label               varchar(128) default NULL,

  FOREIGN KEY (taxon_id) REFERENCES ncbi_taxa_node(taxon_id),
  FOREIGN KEY (genome_db_id) REFERENCES genome_db(genome_db_id),
  FOREIGN KEY (sequence_id) REFERENCES sequence(sequence_id),
  FOREIGN KEY (gene_member_id) REFERENCES member(member_id),

  PRIMARY KEY (member_id),
  UNIQUE source_stable_id (stable_id, source_name),
  KEY (stable_id),
  KEY (source_name),
  KEY (sequence_id),
  KEY (gene_member_id),
  KEY gdb_name_start_end (genome_db_id,chr_name,chr_start,chr_end)
) MAX_ROWS = 100000000 COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'subset'
#

CREATE TABLE subset (
 subset_id      int(10) unsigned NOT NULL AUTO_INCREMENT,
 description    varchar(255),
 dump_loc       varchar(255),

 PRIMARY KEY (subset_id),
 UNIQUE (description)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'subset_member'
#

CREATE TABLE subset_member (
  subset_id   int(10) unsigned NOT NULL,
  member_id   int(10) unsigned NOT NULL,

  FOREIGN KEY (subset_id) REFERENCES subset(subset_id),
  FOREIGN KEY (member_id) REFERENCES member(member_id),

  KEY (member_id),
  PRIMARY KEY subset_member_id (subset_id, member_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'other_member_sequence' (holds any other member-related sequences)
#

CREATE TABLE other_member_sequence (
  member_id                   int(10) unsigned NOT NULL, # unique internal id
  seq_type                    VARCHAR(40) NOT NULL,
  length                      int(10) NOT NULL,
  sequence                    longtext NOT NULL,

  FOREIGN KEY (member_id) REFERENCES member(member_id),

  PRIMARY KEY (member_id, seq_type),
  KEY (seq_type, member_id),
  KEY sequence (sequence(18))
) MAX_ROWS = 10000000 AVG_ROW_LENGTH = 60000 COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'peptide_align_feature'
#
# overview: This tables stores the raw HSP local alignment results
#           of peptide to peptide alignments returned by a BLAST run
#           it is translated from a FeaturePair object
# semantics:
# peptide_align_feature_id  - internal id
# qmember_id                - member.member_id of query peptide
# hmember_id                - member.member_id of hit peptide
# qgenome_db_id             - genome_db_id of query peptide (for query optimization)
# hgenome_db_id             - genome_db_id of hit peptide (for query optimization)
# qstart                    - start pos in query peptide sequence
# qend                      - end  pos in query peptide sequence
# hstart                    - start pos in hit peptide sequence
# hend                      - end  pos in hit peptide sequence
# score                     - blast score for this HSP
# evalue                    - blast evalue for this HSP
# align_length              - alignment length of HSP
# identical_matches         - blast HSP match score
# positive_matches          - blast HSP positive score
# perc_ident                - percent identical matches in the HSP length
# perc_pos                  - percent positive matches in the HSP length
# cigar_line                - cigar string coding the actual alignment

CREATE TABLE peptide_align_feature (

  peptide_align_feature_id    int(10) unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  qmember_id                  int(10) unsigned NOT NULL, # FK member.member_id
  hmember_id                  int(10) unsigned NOT NULL, # FK member.member_id
  qgenome_db_id               int(10) unsigned NOT NULL, # FK genome.genome_id
  hgenome_db_id               int(10) unsigned NOT NULL, # FK genome.genome_id
  qstart                      int(10) DEFAULT 0 NOT NULL,
  qend                        int(10) DEFAULT 0 NOT NULL,
  hstart                      int(11) DEFAULT 0 NOT NULL,
  hend                        int(11) DEFAULT 0 NOT NULL,
  score                       double(16,4) DEFAULT 0.0000 NOT NULL,
  evalue                      double,
  align_length                int(10),
  identical_matches           int(10),
  perc_ident                  int(10),
  positive_matches            int(10),
  perc_pos                    int(10),
  hit_rank                    int(10),
  cigar_line                  mediumtext,

#  FOREIGN KEY (qmember_id) REFERENCES member(member_id),
#  FOREIGN KEY (hmember_id) REFERENCES member(member_id),
#  FOREIGN KEY (qgenome_db_id) REFERENCES genome_db(genome_db_id),
#  FOREIGN KEY (hgenome_db_id) REFERENCES genome_db(genome_db_id),

  PRIMARY KEY (peptide_align_feature_id)
#  KEY hmember_hit (hmember_id, hit_rank)

#  KEY qmember_id  (qmember_id),
#  KEY hmember_id  (hmember_id),
#  KEY hmember_qgenome  (hmember_id, qgenome_db_id),
#  KEY qmember_hgenome  (qmember_id, hgenome_db_id)
) MAX_ROWS = 100000000 AVG_ROW_LENGTH = 133 COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'family'
#

CREATE TABLE family (
  family_id                   int(10) unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  stable_id                   varchar(40) NOT NULL, # unique stable id, e.g. 'ENSFM'.'0053'.'1234567890'
  version                     INT UNSIGNED NOT NULL,# version of the stable_id (changes only when members move to/from existing families)
  method_link_species_set_id  int(10) unsigned NOT NULL, # FK method_link_species_set.method_link_species_set_id
  description                 varchar(255),
  description_score           double,

  FOREIGN KEY (method_link_species_set_id) REFERENCES method_link_species_set(method_link_species_set_id),

  PRIMARY KEY (family_id),
  UNIQUE (stable_id),
  KEY (method_link_species_set_id),
  KEY (description)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'family_member'
#

CREATE TABLE family_member (
  family_id                   int(10) unsigned NOT NULL, # FK family.family_id
  member_id                   int(10) unsigned NOT NULL, # FK member.memeber_id
  cigar_line                  mediumtext,

  FOREIGN KEY (family_id) REFERENCES family(family_id),
  FOREIGN KEY (member_id) REFERENCES member(member_id),

  PRIMARY KEY family_member_id (family_id,member_id),
  KEY (family_id),
  KEY (member_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'domain'
#

CREATE TABLE domain (
  domain_id                   int(10) unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  stable_id                   varchar(40) NOT NULL,
#  source_id                   int(10) NOT NULL,
  method_link_species_set_id  int(10) unsigned NOT NULL, # FK method_link_species_set.method_link_species_set_id
  description                 varchar(255),

  FOREIGN KEY (method_link_species_set_id) REFERENCES method_link_species_set(method_link_species_set_id),

  PRIMARY KEY (domain_id),
  UNIQUE (stable_id, method_link_species_set_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'domain_member'
#

CREATE TABLE domain_member (
  domain_id                   int(10) unsigned NOT NULL, # FK domain.domain_id
  member_id                   int(10) unsigned NOT NULL, # FK member.member_id
  member_start                int(10),
  member_end                  int(10),

  FOREIGN KEY (domain_id) REFERENCES domain(domain_id),
  FOREIGN KEY (member_id) REFERENCES member(member_id),

  UNIQUE (domain_id,member_id,member_start,member_end),
  UNIQUE (member_id,domain_id,member_start,member_end)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE gene_align (
       gene_align_id         int(10) unsigned NOT NULL AUTO_INCREMENT,
	 seq_type              varchar(40),
	 aln_method            varchar(40) NOT NULL DEFAULT '',
	 aln_length            int(10) NOT NULL DEFAULT 0,

  PRIMARY KEY (gene_align_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE gene_align_member (
       gene_align_id         int(10) unsigned NOT NULL,
       member_id             int(10) unsigned NOT NULL,
       cigar_line            mediumtext,

  FOREIGN KEY (gene_align_id) REFERENCES gene_align(gene_align_id),
  FOREIGN KEY (member_id) REFERENCES member(member_id),

  PRIMARY KEY (gene_align_id,member_id),
  KEY member_id (member_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



#
# Table structure for table 'gene_tree_node'
#
# overview:
#   This table holds the gene tree data structure, such as root, relation between
#   parent and child, leaves
#
# semantics:
#      node_id               -- PRIMARY node id
#      parent_id             -- parent node id
#      root_id               -- to quickly isolated nodes of the different rooted tree sets
#      left_index            -- for fast nested set searching
#      right_index           -- for fast nested set searching
#      distance_to_parent    -- distance between node_id and its parent_id

CREATE TABLE gene_tree_node (
  node_id                         int(10) unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  parent_id                       int(10) unsigned,
  root_id                         int(10) unsigned,
  left_index                      int(10) NOT NULL DEFAULT 0,
  right_index                     int(10) NOT NULL DEFAULT 0,
  distance_to_parent              double default 1.0 NOT NULL,
  member_id                       int(10) unsigned,

  FOREIGN KEY (root_id) REFERENCES gene_tree_node(node_id),
  FOREIGN KEY (parent_id) REFERENCES gene_tree_node(node_id),
  FOREIGN KEY (member_id) REFERENCES member(member_id),

  PRIMARY KEY (node_id),
  KEY parent_id (parent_id),
  KEY member_id (member_id),
  KEY root_id (root_id),
  KEY root_id_left_index (root_id,left_index)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'gene_tree_root'
#
# overview:
#   This table holds the gene tree roots
#
# semantics:
#    root_id           - node_id of the root of the tree
#    member_type       - type of members in the tree
#    tree_type         - type of the tree
#    clusterset_id     - name of the set of trees
#    method_link_species_set_id - reference to the method_link_species_set table
#    stable_id         - the main part of the stable_id ( follows the pattern: label(5).release_introduced(4).unique_id(10) )
#    version           - numeric version of the stable_id (changes only when members move to/from existing trees)

CREATE TABLE gene_tree_root (
    root_id                         INT(10) UNSIGNED NOT NULL,
    member_type                     ENUM('protein', 'ncrna') NOT NULL,
    tree_type                       ENUM('clusterset', 'supertree', 'tree') NOT NULL,
    clusterset_id                   VARCHAR(20) NOT NULL DEFAULT 'default',
    method_link_species_set_id      INT(10) UNSIGNED NOT NULL,
    gene_align_id                   INT(10) UNSIGNED,
    ref_root_id                     INT(10) UNSIGNED,
    stable_id                       VARCHAR(40),            # unique stable id, e.g. 'ENSGT'.'0053'.'1234567890'
    version                         INT UNSIGNED,           # version of the stable_id (changes only when members move to/from existing trees)

    FOREIGN KEY (root_id) REFERENCES gene_tree_node(node_id),
    FOREIGN KEY (method_link_species_set_id) REFERENCES method_link_species_set(method_link_species_set_id),
    FOREIGN KEY (gene_align_id) REFERENCES gene_align(gene_align_id),
    FOREIGN KEY (ref_root_id) REFERENCES gene_tree_root(root_id),

    PRIMARY KEY (root_id ),
    UNIQUE KEY ( stable_id ),
    KEY ref_root_id (ref_root_id),
    KEY (tree_type)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



#
# Table structure for table 'gene_tree_node_tag'
#
# overview:
#    to allow the tagging of nodes.
#
# semantics:
#    node_id             -- node_id foreign key from gene_tree_node table
#    tag                 -- tag used to fecth/store a value associated to it
#    value               -- value associated with a particular tag

CREATE TABLE gene_tree_node_tag (
  node_id                int(10) unsigned NOT NULL,
  tag                    varchar(50) NOT NULL,
  value                  mediumtext NOT NULL,

  FOREIGN KEY (node_id) REFERENCES gene_tree_node(node_id),

  KEY node_id_tag (node_id, tag),
  KEY (node_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'gene_tree_root_tag'
#
# overview:
#    allows to tag trees, via their root
#
# semantics:
#    root_id             -- root_id foreign key from gene_tree_root table
#    tag                 -- tag used to fecth/store a value associated to it
#    value               -- value associated with a particular tag

CREATE TABLE gene_tree_root_tag (
  root_id                int(10) unsigned NOT NULL,
  tag                    varchar(50) NOT NULL,
  value                  mediumtext NOT NULL,

  FOREIGN KEY (root_id) REFERENCES gene_tree_root(root_id),

  KEY root_id_tag (root_id, tag),
  KEY (root_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



#
# Table structure for table 'gene_tree_node_attr'
#
# overview:
#    to allow attributes for nodes
#
# semantics:
#    node_id                         -- node_id foreign key from gene_tree_node table
#    duplication                     -- Currently 0 for speciations, 2 for well supported duplications, 1 for dubious duplications or duplications at the root
#    taxon_id                        -- Only present after reconciliation, links to ncbi_taxa_node
#    taxon_name                      -- Only present after reconciliation, the name of the species refered to by taxon_id
#    bootstrap                       -- A bootstrap value
#    duplication_confidence_score    -- Only for duplications: the ratio between the number of species in the intersection by the number of the species in the union

# The following foreign key is honoured in Ensembl Compara
#  FOREIGN KEY (taxon_id) REFERENCES ncbi_taxa_node(taxon_id),
# In some Ensembl Genomes, it should be
#  FOREIGN KEY (taxon_id) REFERENCES genome_db(genome_db_id),

CREATE TABLE gene_tree_node_attr (
  node_id                         INT(10) UNSIGNED NOT NULL,
  node_type                       ENUM("duplication", "dubious", "speciation", "gene_split"),
  taxon_id                        INT(10) UNSIGNED,
  taxon_name                      VARCHAR(255),
  bootstrap                       TINYINT UNSIGNED,
  duplication_confidence_score    DOUBLE(5,4),

  FOREIGN KEY (node_id) REFERENCES gene_tree_node(node_id),

  PRIMARY KEY (node_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE hmm_profile (
  model_id                    varchar(40) NOT NULL,
  name                        varchar(40),
  type                        varchar(40) NOT NULL,
  hc_profile                  mediumtext,
  consensus                   mediumtext,

  PRIMARY KEY (model_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



#
# Table structure for table 'homology'
#

CREATE TABLE homology (
  homology_id                 int(10) unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  method_link_species_set_id  int(10) unsigned NOT NULL, # FK method_link_species_set.method_link_species_set_id
  description                 ENUM('ortholog_one2one','apparent_ortholog_one2one','ortholog_one2many','ortholog_many2many','within_species_paralog','other_paralog','putative_gene_split','contiguous_gene_split','between_species_paralog','possible_ortholog','UBRH','BRH','MBRH','RHS', 'projection_unchanged','projection_altered'),
  subtype                     varchar(40) NOT NULL DEFAULT '',
  dn                          float(10,5),
  ds                          float(10,5),
  n                           float(10,1),
  s                           float(10,1),
  lnl                         float(10,3),
  threshold_on_ds             float(10,5),
  ancestor_node_id            int(10) unsigned NOT NULL,
  tree_node_id                int(10) unsigned NOT NULL,

  FOREIGN KEY (method_link_species_set_id) REFERENCES method_link_species_set(method_link_species_set_id),
  FOREIGN KEY (ancestor_node_id) REFERENCES gene_tree_node(node_id),
  FOREIGN KEY (tree_node_id) REFERENCES gene_tree_root(root_id),

  PRIMARY KEY (homology_id),
  KEY (method_link_species_set_id),
  KEY (ancestor_node_id),
  KEY (tree_node_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'homology_member'
#

CREATE TABLE homology_member (
  homology_id                 int(10) unsigned NOT NULL, # FK homology.homology_id
  member_id                   int(10) unsigned NOT NULL, # FK member.member_id
  peptide_member_id           int(10) unsigned, # FK member.member_id
  cigar_line                  mediumtext,
  perc_cov                    int(10),
  perc_id                     int(10),
  perc_pos                    int(10),

  FOREIGN KEY (homology_id) REFERENCES homology(homology_id),
  FOREIGN KEY (member_id) REFERENCES member(member_id),
  FOREIGN KEY (peptide_member_id) REFERENCES member(member_id),

  PRIMARY KEY homology_member_id (homology_id,member_id),
  KEY (homology_id),
  KEY (member_id),
  KEY (peptide_member_id)
) MAX_ROWS = 300000000 COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'mapping_session'
#
# overview:
#      A single mapping_session is the event when mapping between two given releases
#      for a particular class type ('family' or 'tree') is loaded.
#      The whole event is thought to happen momentarily at 'when_mapped' (used for sorting in historical order).

CREATE TABLE mapping_session (
    mapping_session_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    type               ENUM('family', 'tree'),
    when_mapped        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rel_from           INT UNSIGNED,
    rel_to             INT UNSIGNED,
    prefix             CHAR(4) NOT NULL,
    PRIMARY KEY ( mapping_session_id ),
    UNIQUE KEY  ( type, rel_from, rel_to, prefix )

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


#
# Table structure for table 'stable_id_history'
#
# overview:
#      'stable_id_history' table keeps the history of stable_id changes from one release to another.
#
#      The primary key 'object' describes a set of members migrating from stable_id_from to stable_id_to.
#      Their volume (related to the 'shared_size' of the new class) is reflected by the fractional 'contribution' field.
#
#      Since both stable_ids are listed in the primary key,
#      they are not allowed to be NULLs. We shall treat empty strings as NULLs.
#
#      If stable_id_from is empty, it means these members are newcomers into the new release.
#      If stable_id_to is empty, it means these previously known members are disappearing in the new release.
#      If both neither stable_id_from nor stable_id_to is empty, these members are truly migrating.

CREATE TABLE stable_id_history (
    mapping_session_id INT UNSIGNED NOT NULL,
    stable_id_from     VARCHAR(40) NOT NULL DEFAULT '',
    version_from       INT UNSIGNED NULL DEFAULT NULL,
    stable_id_to       VARCHAR(40) NOT NULL DEFAULT '',
    version_to         INT UNSIGNED NULL DEFAULT NULL,
    contribution       FLOAT,

    FOREIGN KEY (mapping_session_id) REFERENCES mapping_session(mapping_session_id),

    PRIMARY KEY ( mapping_session_id, stable_id_from, stable_id_to )

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


# Table sitewise_aln
# This table stores the values of calculating the sitewise dN/dS ratio
#  on node_ids (subtrees) for the GeneTrees. A subtree can also be the
#  root of the tree
# sitewise_id - identifies the sitewise entry
# aln_position - is the position in the whole GeneTree alignment, even
# if it is all_gaps in the subtree
# node_id - is the root of the subtree for which the sitewise is
# calculated
# tree_node_id - is the root of the tree. it will be equal to node_id
# if we are calculating sitewise for the whole tree
# omega is the estimated omega value at the position
# omega_lower is the lower bound of the confidence interval
# omega_upper is the upper bound of the confidence interval
# threshold_on_branch_ds is the used threshold to break a tree into
# subtrees when the dS value of a given branch is too big. This is
# defined in the configuration file for the genetree pipeline
# type is the predicted type for the codon/aminoacid
# (positive4,positive3,positive2,positive1,
#  negative4,negative3,negative2,negative1,
#  constant,all_gaps,single_character,synonymous,default)

CREATE TABLE sitewise_aln (
  sitewise_id                 int(10) unsigned NOT NULL AUTO_INCREMENT, # unique internal id
  aln_position                int(10) unsigned NOT NULL,
  node_id                     int(10) unsigned NOT NULL,
  tree_node_id                int(10) unsigned NOT NULL,
  omega                       float(10,5),
  omega_lower                 float(10,5),
  omega_upper                 float(10,5),
  optimal                     float(10,5),
  ncod                        int(10),
  threshold_on_branch_ds      float(10,5),
  type                        ENUM('single_character','random','all_gaps','constant','default','negative1','negative2','negative3','negative4','positive1','positive2','positive3','positive4','synonymous') NOT NULL,

  FOREIGN KEY (node_id) REFERENCES gene_tree_node(node_id),

  UNIQUE aln_position_node_id_ds (aln_position,node_id,threshold_on_branch_ds),
  PRIMARY KEY (sitewise_id),
  KEY (tree_node_id),
  KEY (node_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



# ---------------------------------- CAFE tables --------------------------------


#
# Table structure for species_tree_node
#
# species_tree_node holds the information for each node of the species_tree
#
# For information of each field see the gene_tree_node table 

CREATE TABLE `species_tree_node` (
  `node_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` int(10) unsigned,
  `root_id` int(10) unsigned,
  `left_index` int(10) NOT NULL DEFAULT 0,
  `right_index` int(10) NOT NULL DEFAULT 0,
  `distance_to_parent` double DEFAULT '1',

  PRIMARY KEY (`node_id`),
  KEY `parent_id` (`parent_id`),
  KEY `root_id` (`root_id`,`left_index`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


#
# Table structure for species_tree_root
#
# species_tree_root is a header table for species_tree_node
#
# root_id                    -- The root_id of the species_tree
# method_link_species_set_id -- Links to method_link_species_set table
# species_tree               -- The whole tree in newick format
# pvalue_lim                 -- The pvalue threshold used in the CAFE analysis
#

CREATE TABLE `species_tree_root` (
  `root_id` int(10) unsigned NOT NULL,
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `species_tree` mediumtext,
  `pvalue_lim` double(5,4) DEFAULT NULL,

  FOREIGN KEY (root_id) REFERENCES species_tree_node(node_id),
  FOREIGN KEY (method_link_species_set_id) REFERENCES method_link_species_set(method_link_species_set_id),

  PRIMARY KEY (root_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


#
# Table structure for species_tree_node_tag
#
# species_tree_node_tag stores additional information for each species_tree_node
#
# For information on each fied see any other *_tag table
#

CREATE TABLE `species_tree_node_tag` (
  `node_id` int(10) unsigned NOT NULL,
  `tag` varchar(50) NOT NULL,
  `value` mediumtext NOT NULL,

  FOREIGN KEY (node_id) REFERENCES species_tree_node(node_id),

  KEY `node_id_tag` (`node_id`,`tag`),
  KEY `tag_node_id` (`tag`,`node_id`),
  KEY `node_id` (`node_id`),
  KEY `tag` (`tag`)
  
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


#
# Table structure for CAFE_gene_family
#
# CAFE_gene_family holds information about each CAFE gene family
#
# cafe_gene_family_id    -- Primary key for linking with CAFE_species_gene
# root_id                -- Links to root_ids in the species_tree_root table
# lca_id                 -- Links to node_ids in the species_tree_node table
#                           Refers to the actual lowest common ancestor for the family
# gene_tree_root_id      -- Links to the gene_tree_root table
# pvalue_avg             -- The average pvalue for the gene family as reported by CAFE
# lambdas                -- The lambda/s values reported/used by CAFE

CREATE TABLE `CAFE_gene_family` (
  `cafe_gene_family_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `root_id` int(10) unsigned NOT NULL,
  `lca_id` int(10) unsigned NOT NULL,
  `gene_tree_root_id` int(10) unsigned NOT NULL,
  `pvalue_avg` double(5,4) DEFAULT NULL,
  `lambdas` varchar(100) DEFAULT NULL,

  FOREIGN KEY (root_id) REFERENCES species_tree_root(root_id),
  FOREIGN KEY (lca_id) REFERENCES species_tree_node(node_id),
  FOREIGN KEY (gene_tree_root_id) REFERENCES gene_tree_root(root_id),

  PRIMARY KEY (`cafe_gene_family_id`),
  KEY `root_id` (`root_id`),
  KEY `gene_tree_root_id` (`gene_tree_root_id`)
) ENGINE=MyISAM AUTO_INCREMENT=10 DEFAULT CHARSET=latin1;


#
# Table structure for CAFE_species_gene
#
# CAFE_species_gene stores per species_tree_node information about for each gene_family
#
# cafe_gene_family_id  -- Links to CAFE_gene_family
# node_id              -- Links to species_tree_node. The species_tree_node this entry refers to
# taxon_id             -- The taxon_id for this node
# n_members            -- The number of members for the node as reported by CAFE
# pvalue               -- The pvalue of the node as reported by CAFE

CREATE TABLE `CAFE_species_gene` (
  `cafe_gene_family_id` int(10) unsigned NOT NULL,
  `node_id` int(10) unsigned NOT NULL,
  `taxon_id` int(10) unsigned DEFAULT NULL,
  `n_members` int(4) unsigned NOT NULL,
  `pvalue` double(5,4) DEFAULT NULL,

  FOREIGN KEY (cafe_gene_family_id) REFERENCES CAFE_gene_family(cafe_gene_family_id),
  FOREIGN KEY (node_id) REFERENCES species_tree_node(node_id),

  KEY `cafe_gene_family_id` (`cafe_gene_family_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- Table structure for table `CAFE_data`                                              
                                                                                      
SET @saved_cs_client     = @@character_set_client;                                    
SET character_set_client = utf8;                                                      
CREATE TABLE `CAFE_data` (                                                            
  `fam_id` varchar(20) NOT NULL,                                                      
  `tree` mediumtext NOT NULL,                                                         
  `tabledata` mediumtext NOT NULL,                                                    
  PRIMARY KEY (`fam_id`)                                                              
) ENGINE=MyISAM DEFAULT CHARSET=latin1;                                               
SET character_set_client = @saved_cs_client;


# ------------------------ End of CAFE tables --------------------------------------

# Auto add schema version to database (this will override whatever hive puts there)
REPLACE INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'schema_version', '70');

#Add schema type
INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'schema_type', 'compara');
