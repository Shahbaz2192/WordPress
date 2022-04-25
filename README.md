# WordPress Deployment Architecture


           Some config data            (Secrets Created so that environment variable can connect from DB to Application)
             |
             |
             |
             |         MySQL PVC                   (For Persistent Volume Claim)
    |--------|         MySQL Service               (MySQL replicaset) 
    |--------MySQL Container             (MySQL Deployment)    
    |--------WordPress Container         (Wordpress deployment)
                       WordPress PVC               (For Persistent Volume Claim)
                       Loadbalancer                 (service to expose exteranlly)
    
    
    
And for multiregion, during deployment of GKE from terraform, we'll be using Variables and define the different regions in the variables, and interpolation those values by using loops, but in terraform we use, count.index method instead of loops. Which is mentioned in the terraform code and respective variable file.
    
