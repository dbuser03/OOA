**BUSER DANIELE 894514**

---

INTRODUZIONE

Ai tempi di Simula e del primo Smalltalk, molto molto tempo prima di
Python, Ruby, Perl e SLDJ, i programmatori Lisp giá producevano una
pletora di linguaggi object oriented. Il vostro progetto consiste
nella costruzione di un’estensione “object oriented” di Common Lisp,
chiamata OOΛ, e di un’estensione “object oriented” di Prolog, chiamata
OOΠ.

---

**OOΛ**

Le primitive di OOΛ sono essenzialmente quattro: def-class, make,
field e field\*.

---

**def_class**

La primitiva `def-class` prende due argomenti: il nome della classe e
una lista di campi e metodi. I campi sono coppie di nome e valore,
mentre i metodi sono liste di nomi di parametri e corpo del metodo.

Ad esempio, la seguente istruzione definisce una classe `Student` con
due campi, `name` e `university`, e un metodo `talk()`:

```
(def-class ’student ’(person)
	’(fields (name "Eva Lu Ator") (university "Berkeley" string))
	’(methods
		(talk (&optional (out *standard-output*))
			(format out "My name is ~A~%My age is ~D~%"
			(field this ’name) (field this ’age)))))
```

---

**make**

La primitiva `make` prende due argomenti: nome della classe e una
lista di campi. Per creare l'istanza viene scorsa tutta la lista di
campi e viene creata una lista strutturata come segue

`oolinst class-name [field-name, field-value]*`

Ad esempio, la seguente istruzione definisce un'istanza `s1` con due
campi, `name "Eduardo De Filippo"` e `age 108`:

```
(defparameter s1 (make ’student ’name "Eduardo De Filippo" ’age 108))
```

---

**field**

La primitiva `field` prende due argomenti: un'istanza e il nome del
campo di cui si vuole estrarre il valore. Per fare ció viene scorse
tutte le coppie `[field-name, field-value]` e viene estratto il valore
del campo desiderato.

Ad esempio, la seguente istruzione estrae il valore del campo `age`
dell'istanza `s1`:

```
(field s1 'age)
```

---

**field\***

La primitiva `field*` prende due argomenti: un'istanza e una lista di
field-name. Questa funzione ritorna il valore associato all'ultimo
elemento della lista field-name nell'ultima istanza.

Ad esempio, la seguente istruzione deve ritornare `T`:

```
(eq (field (field (field I ’s1) ’s2) ’s3)
	(field* I ’s1 ’s2 ’s3))
```

---

ALTRE FUNZIONI UTILIZZATE PER QUESTO PROGETTO

- `is-class` : prende in input il nome di una classe e ritorna T se
  questa é presente nella nostra hash-table.
- `is-instance` : prende in input un'istanza e il nome di una classe
  (opzionale) ritorna T se l'istanza é tale o se é istanza della
  classe specificata.

- `check-parts` : prende in input una lista di campi e metodi e
  controlla che sia effettivamente composta solo da campi e metodi.
- `extract-parts` : prende in input il nome di una classe e ritorna la
  lista composta dai suoi campi e metodi.
- `part-structure` : prende in input una lista di campi e metodi e li
  processa per creare la lista della classe.
- `fields-part` : prende in input i campi di una classe e crea la
  struttura per ognuno di questi.
- `methods-part` : prende in input i metodi di una classe e crea la
  struttura per ognuno di questi.
- `process-method` : prende in input il nome di un metodo, le sue
  specifiche e crea la trampoline function.
- `rewrite-method-code` : prende in input le specifiche di un metodo
  rimpiazza "this" e restituisce il corpo del metodo aggiornato.
- `extract-method` : prende in input un'istanza e il nome di un metodo
  e ritorna il metodo richiesto se é presente nella classe
  dell'istanza o nelle sue superclassi.
- `extract-field` : prende in input il nome di una classe e il nome di
  un campo e ritorna il campo richiesto se é presente nella classe o
  nelle sue superclassi.
- `extract-superclasses` : prende in input il nome di una classe e
  ritorna una lista con tutte le superclassi dirette ed indirette.
- `filter-fields` : prende in input una lista di campi e metodi e
  ritorna una lista contenente solo i campi.
- `filter-methods` : prende in input una lista di campi e metodi e
  ritorna una lista contenente solo i metodi.
- `check-field-type-compatibility` : prende in input il valore di un
  campo e il tipo di un campo e controlla che siano compatibili.
- `check-field-type-inheritance` : prende in input una classe
  (sottoclasse) e controlla che i tipi dei campi in comune con la
  superclasse non siano piú ampi.
