(define-module (services redshift)
  #:use-module (gnu)
  #:use-module (gnu home services desktop)
  #:export (redshift-service))

(define (redshift-service)
  (service home-redshift-service-type
           (home-redshift-configuration
            (location-provider 'manual)
            (daytime-temperature 3500) ; no blue light for me ;) 
            (nighttime-temperature 3000)
            (latitude 35.81)    
            (longitude -0.80))))
