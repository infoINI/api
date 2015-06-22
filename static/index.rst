JSON API
========

Allgemeine Platzhalter:

* ``STRING`` JSON String, z.B.: ``"test"``
* ``INT`` JSON Ganzzahl z.B.: ``2``
* ``FLOAT`` JSON Float z.B.: ``0.2``

GET /api/combined.json
----------------------
``door.json`` und ``cafe.json`` in einem Objekt kombiniert

GET /api/door.json
------------------
Status der ini-Raum Tür

Struktur::

    {
        "status": STATUS
    }


Platzhalter:

* ``STATUS``
    * ``"OPEN"``
    * ``"CLOSED"``

TODO:
Long polling URL: ``/api/door.event.json``

GET /api/cafe.json
------------------

Aktueller Füllstand der Kaffeekannen.

Struktur::

    { "pots" : 
        [ 
            { 
                "status" : STATUS ,
                "level": LEVEL
            },
            ..
        ]
    }

Platzhalter:

* ``STATUS`` Status der Kanne
    * ``"AVAILIBLE"``
    * ``"UNAVAILIBLE"``
* ``LEVEL`` Füllstand der Kanne in Prozent
    * ``0`` bis ``100``
    * ``undefined``

TODO:
Long polling URL: ``/api/cafe.event.json``

GET /api/donations.json
-----------------------

Spenden

Struktur::

    { "donations
        [
            {
                "item" : STRING,
                "price" : PRICE
            },
            ..
        ]
    }

Platzhalter:
* ``PRICE`` Preis in Euro, (``FLOAT``)

GET /api/members.json
---------------------

Übersicht der FSR Mitglieder

Struktur::

    { "members" :
        [
            {
                "firstname" : STRING,
                "lastname" : STRING,
                "position" : STRING,
                "course_of_study" : STRING,
                "photo_url" : PHOTO_URL,
                "email" : STRING
            },
            ..
        ]
    }

Platzhalter:

* ``PHOTO_URL`` String, http/https URL zu einem Bild
  Fotos können in einem Ordnern in der Galerie Hinterlegt werden:
  http://infoini.de/photos
  Das Foto sollte die Dimensionen ??x?? haben.

GET /api/raumplan.pdf
---------------------

pdf-Datei: INI-Raumplan (Öffnungszeiten)


GET /api/zuendstoff.pdf
-----------------------

pdf-Datei: Aktuelles Erstsemesterheft Zündstoff

Alle ausgaben sind hier zu finden: http://infoini.de/redmine/projects/fsropen/wiki/Zuendstoff


Redmine
-------

Das installierte Redmine bietet auch aine JSON API:

http://www.redmine.org/projects/redmine/wiki/Rest_api
