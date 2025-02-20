#!/usr/bin/guile
!#
;; This script reads a recutils file and outputs an SXML table.
;; It skips header lines (those beginning with “%”) and splits the file into
;; records separated by blank lines. Each record is parsed as key-value pairs,
;; and then an SXML table is produced with a header row and one row per record.

;; Import regex functions for trimming whitespace.
(use-modules (ice-9 regex))
(use-modules (ice-9 rdelim))

;; Trim leading and trailing whitespace from a string.
(define (string-trim s)
  (regexp-replace #px"^\\s+|\\s+$" s ""))

;; Check if STR starts with PREFIX.
(define (string-prefix? prefix str)
  (let ((len (string-length prefix)))
    (and (<= len (string-length str))
         (string=? prefix (substring str 0 len)))))

;; Read all lines from a file.
(define (read-file filename)
  (call-with-input-file filename
    (lambda (in)
      (let loop ((lines '()))
        (let ((line (read-line in 'any)))
          (if (eof-object? line)
              (reverse lines)
              (loop (cons line lines))))))))

;; Remove header lines (those starting with "%" or empty)
;; until the first non-header line is found.
(define (remove-header-lines lines)
  (let loop ((lines lines))
    (if (null? lines)
        '()
        (if (or (string-prefix? "%" (car lines))
                (string=? (car lines) ""))
            (loop (cdr lines))
            lines))))

;; Split the remaining lines into records.
;; A record is a group of non-empty lines separated by blank lines.
(define (split-records lines)
  (let loop ((lines lines) (current '()) (records '()))
    (cond
      ((null? lines)
       (if (null? current)
           (reverse records)
           (reverse (cons (reverse current) records))))
      (else
       (let ((line (car lines)))
         (if (string=? line "")
             (if (null? current)
                 (loop (cdr lines) '() records)
                 (loop (cdr lines) '() (cons (reverse current) records)))
             (loop (cdr lines) (cons line current) records)))))))

;; Given a line of the form "Key: Value", split into a pair.
(define (split-key-value line)
  (let ((pos (string-index line #\:)))
    (if pos
        (list (string-trim (substring line 0 pos))
              (string-trim (substring line (+ pos 1))))
        (list line ""))))

;; Parse a record (list of lines) into an association list of key/value pairs.
(define (parse-record record-lines)
  (map split-key-value record-lines))

;; Get the union of keys from all records.
(define (all-keys records)
  (let loop ((records records) (keys '()))
    (if (null? records)
        (reverse keys)
        (let ((record (car records)))
          (loop (cdr records)
                (foldl (lambda (pair acc)
                         (let ((k (car pair)))
                           (if (member k acc)
                               acc
                               (cons k acc))))
                       keys
                       record))))))

;; Retrieve the value for KEY in a record (association list),
;; returning the empty string if KEY is not present.
(define (get-value key record)
  (let ((pair (assoc key record)))
    (if pair
        (cdr pair)
        "")))

;; Build an SXML table given the list of keys and the list of records.
(define (sxml-table keys records)
  (list 'table
        (list 'thead
              (list 'tr
                    (map (lambda (key) (list 'th key)) keys)))
        (list 'tbody
              (map (lambda (record)
                     (list 'tr
                           (map (lambda (key)
                                  (list 'td (get-value key record)))
                                keys)))
                   records))))

;; Main procedure: read the file, parse records, build the table, and print it.
(define (main args)
  (if (null? args)
      (begin
        (display "Usage: rec-to-sxml filename\n")
        (exit 1))
      (let* ((filename (car args))
             (lines (read-file filename))
             (record-lines (remove-header-lines lines))
             (records-split (split-records record-lines))
             (parsed-records (map parse-record records-split))
             (keys (all-keys parsed-records))
             (table (sxml-table keys parsed-records)))
        (write table)
        (newline)
        (exit 0))))

(main (command-line-arguments))
