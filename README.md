# pki-generator
Create Root and Intermediate CAs

gen_ca.sh creates the root CA
gen_intermediate.sh creates the intermediate CA signed by the root CA
gen_leaf.sh creates a leaf cert signed by an intermediate, this is more of an example. Does now currently support SAN's.
