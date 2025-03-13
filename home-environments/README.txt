File Structure

home/
├── home-configuration.scm      # Main file that imports and combines everything
├── packages.scm                # All package definitions 
├── services/                   # Configurations in guile scheme
│   ├── bash.scm                
│   ├── stumpwm.scm             
│   ├── lem.scm                  
│   ├── git.scm                 
│   └── redshift.scm             
├── services/
    ├── files/.config/          # Configurations not yet ported to guile scheme
