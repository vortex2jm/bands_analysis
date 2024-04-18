% João Paulo Moura Clevelares
% O dataset é sobre bandas musicais

:- data_source(
dbpedia_bands,
sparql("
PREFIX schema: <http://schema.org/>
PREFIX dbp: <http://dbpedia.org/property/>
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT distinct ?band_uri ?band_name (sample(?genre) as ?genre) (sample(?origin) as ?origin) ?start (sample(?record) as ?record) (sample(?rec_founding_year) as ?rec_founding_year)
WHERE {
  ?band_uri a schema:MusicGroup ;
        rdfs:label ?band_name ;
        dbp:origin ?origin_uri ;
        dbo:activeYearsStartYear ?start ;
        dbo:recordLabel ?record_uri;
        dbp:genre ?genre_uri .
  
  ?genre_uri rdfs:label ?genre .
  ?origin_uri rdfs:label ?origin .
  ?record_uri rdfs:label ?record ;
              dbo:foundingYear ?rec_founding_year .
  
   filter(lang(?genre) = 'en')
   filter(lang(?band_name) = 'en')
   filter(lang(?origin) = 'en')
   filter(lang(?record) = 'en')
}

order by asc (?band_name)
",
[ endpoint('https://dbpedia.org/sparql')])  ).

% Relaciona as colunas do dataset com as variáveis
bands(BandName, Genre, Origin, Start, Record, RecFY) :- 
    dbpedia_bands{band_name:BandName, genre:Genre, origin: Origin, start:Start, record:Record, rec_founding_year: RecFY}.

% Relaciona as colunas do dataset com as variáveis
records(Record, RecFY) :- 
    dbpedia_bands{record:Record, rec_founding_year: RecFY} .

% Regra 1
% É banda de pop fundada antes do ano especificado
is_pop_band_founded_before_year(Band, Year) :-
    bands(Band, Genre, _, FoundedYear, _, _),
    sub_string(Genre, _, _, _, 'pop'),
    FoundedYear < Year.
% Consultas %
% is_pop_band_founded_before_year(Band, 1990)


% Regra 2
% Há mais de uma banda do mesmo local
has_multiple_bands_from_same_location(Location) :-
    findall(Band, bands(Band, _, Location, _, _, _), Bands),
    length(Bands, Count),
    Count > 1.
% Consultas %
% has_multiple_bands_from_same_location(Location)
% has_multiple_bands_from_same_location("England")
% has_multiple_bands_from_same_location("Zwolle")


% Regra 3 %
% Banda assinada com uma gravadora e o nome começa com a letra especificada
signed_with_record_and_start_with_char(Band, Record, StartChar) :-
	bands(Band, _, _, _, RecordLabel, _),
    (Record = RecordLabel),
    atom_chars(Band, [StartChar|_]) .
% Consultas %
% signed_with_record_and_start_with_char(Band, Record, StartLetter)
% signed_with_record_and_start_with_char("14 Bis (band)", Record, StartChar)
% signed_with_record_and_start_with_char("14 Bis (band)", "Epic Records", StartChar)
% signed_with_record_and_start_with_char("14 Bis (band)", "Epic Records", '1')
% signed_with_record_and_start_with_char("14 Bis (band)", "Epic Records", 'A')
% signed_with_record_and_start_with_char("17 Hippies", "Epic Records", '1')
% signed_with_record_and_start_with_char("17 Hippies", "Elektra Records", '1')


% Regra 4 %
% Bandas com a mesma idade e mesma gravadora
same_age_bands_with_same_record(Band1, Band2) :-
    bands(Band1, _, _, Age, Record, _),
    bands(Band2, _, _, Age, Record, _),
    Band1 @< Band2 .
% O '@<' garante que apenas uma combinação de bandas seja considerada, evitando duplicatas
% Consultas %
% same_age_bands_with_same_record(Band1, Band2)
% same_age_bands_with_same_record(Band1, "Tussle")
% same_age_bands_with_same_record("120 Days", "Tussle")
% same_age_bands_with_same_record("120 Days", "Dosh (musician)")


% Regra 5
% Gravadora mais antiga
oldest_record(RecordLabel) :-
    aggregate_all(min(RFY), records(RecordLabel, RFY), OldestYear),
    bands(_, _, _, _, RecordLabel, OldestYear),
    ! .
% Se não colocar o corte, o programa repete a mesma gravadora várias vezes
% Neste caso, a wichita records aparece com foundingYear = 0022, por conta 
% de um problema nos dados da dbpedia, no entanto, a consulta funciona (:
% oldest_record(RecordLabel)
% oldest_record("Wichita Recordings")
% oldest_record("12 Rods")


% Regra 6 %
% Bandas mais velhas que suas próprias gravadoras
bands_older_than_its_records(Band) :-
    bands(Band, _, _, BandStart, _, RecFY),
    BandStart < RecFY .
% Consultas %
% bands_older_than_its_records(Band)
% bands_older_than_its_records("12 Rods")


% Regra 7 %
% Lista gravadoras assinadas com bandas de metal
records_signed_with_metal_bands(Record) :-
    findall(Record, (bands(_, Genre, _, _, Record, _), sub_string(Genre, _, _, _, 'metal')), AllRecords),
    list_to_set(AllRecords, Record) .
% Consultas %
% records_signed_with_metal_bands(Record)
% Se colocarmos o nome de alguma gravadora, ela sempre vai retornar falso


% Regra 8 %
% Lista todos os subgeneros do rock e do metal (ordenados)
all_metal_and_rock_subgeneres_sorted(Genres) :-
    findall(Genre, (bands(_, Genre, _, _, _, _), (sub_string(Genre, _, _, _, 'rock') ;
    sub_string(Genre, _, _, _, 'metal'))), UnsortedGenres),
    sort(UnsortedGenres, Genres) .     

% Consultas %
% all_metal_and_rock_subgeneres_sorted(Genres)
% Se colocarmos o nome de algum genero, ela sempre vai retornar falso
