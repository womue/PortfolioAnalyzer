# Fields PortfolioAnalyzer

A simple list of fields used by the client and the UI and configured in the schema.xml. 

A field can be:
* _indexed_: it can be searched for. 
	* Indexing can take many different _analysis_ so that queries offer a given tolerance.:
		* _string_: verbatim, only complete match
		* _english stemmer_: a typically English-oriented analysis, converting, e.g. _converting_ to _convert_
		* _german stemmer_: similar, but for the German language, converts, e.g., _Übungen_  to _ubung_ so that querying "übung" or "ubung" all match documents that contain "Übungen".
		* _phonetic_: applies the metaphone or soundex conversion
* _stored_: its value can be restored when pulled with a result's document. 
* _multivalued_: 

Storing and indexing have a price in memory, disk, and bandwidth and should be minimized.

Sorting can only be done on indexed and single-valued fields. (I think)
Highlighting can only be done on stored fields. (I think)
Facetting can only be done on indexed and stored fields. (I think)

## Fields
* _portfolio_title_: German stemming, stored and indexed
* _title_: German stemming, stored and indexed
* _local_storage_dir_: string, stored and and indexed
* _author_: German stemming, stored and indexed
* _url_: string, stored and indexed
	* potentially copied to a standard-analyzer field so to query partial domains
* _text_: German stemming, indexed and stored.
* _indexDate_: Date when the document is put into index (auto-completed)
* _lastModified_: Date when the portfolio was last changed

