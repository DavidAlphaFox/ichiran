(in-package :ichiran/dict)

;; SPLITS (words that should be scored as two or more other words)

(defparameter *split-map* (make-hash-table)) ;; seq -> split function

(defmacro defsplit (name seq (reading-var) &body body)
  `(progn
     (defun ,name (,reading-var) ;; reading -> (values parts score-bonus)
       ,@body)
     (setf (gethash ,seq *split-map*) ',name)))

(defmacro def-simple-split (name seq score (&optional length-var text-var reading-var) &body parts-def)
  "each part is (seq length-form)"
  (alexandria:with-gensyms (offset parts pseq part-length)
    (unless name (setf name (intern (format nil "~a~a" :split- seq))))
    (unless reading-var (setf reading-var (gensym "RV")))
    (unless length-var (setf length-var (gensym "LV")))
    (unless text-var (setf text-var (gensym "TV")))
    `(defsplit ,name ,seq (,reading-var)
       (let* ((,text-var (true-text ,reading-var))
              (,length-var (length ,text-var))
              (,offset 0)
              (,parts nil))
         (declare (ignorable ,text-var ,length-var))
         ,@(loop for (part-seq part-length-form conj-p rendaku-p) in parts-def
              if (eql part-seq :test)
                collect
                `(unless ,part-length-form
                   (return-from ,name nil))
              else
              collect
                `(let ((,pseq ,(if (listp part-seq)
                                   (if (and part-seq (stringp (car part-seq)))
                                       `(list (seq (car (find-word-conj-of ,@part-seq))))
                                       `',part-seq)
                                   `',(list part-seq)))
                       (,part-length ,part-length-form))
                   (push (car (apply
                               ,(if conj-p
                                   ''find-word-conj-of
                                   ''find-word-seq)
                                (let ((part-txt (subseq ,text-var ,offset
                                                       (and ,part-length (+ ,offset ,part-length)))))
                                  ,(if rendaku-p
                                      '(unrendaku part-txt)
                                      'part-txt))
                                ,pseq))
                         ,parts)
                   (when ,part-length
                     (incf ,offset ,part-length))))
         (values (nreverse ,parts) ,score)))))

(defun get-split* (reading &optional conj-of)
  (let ((split-fn (gethash (seq reading) *split-map*)))
    (if split-fn
        (funcall split-fn reading)
        (loop for seq in conj-of
           for split-fn = (gethash seq *split-map*)
           when split-fn do (return (funcall split-fn reading))))))

(defun get-split (reading &optional conj-of)
  "Includes safety check if one of split words is missing"
  (multiple-value-bind (split score) (get-split* reading conj-of)
    (when (and split (every 'identity split))
      (values split score))))

;; split definitions

;; -de expressions (need to be split otherwise -desune parses as -de sune)

#|
(:select 'kt.seq 'kt.text
                :from (:as 'kanji-text 'kt) (:as 'sense-prop 'sp)
                :where (:and (:like 'kt.text "%で")
                             (:= 'sp.seq 'kt.seq) (:= 'sp.tag "pos")
                             (:= 'sp.text "exp")))
|#

(defmacro def-de-split (seq seq-a &key (score 20))
  (let ((name (intern (format nil "~a~a" :split-de- seq))))
    `(def-simple-split ,name ,seq ,score (len)
       (,seq-a (- len 1))
       (2028980 1))))

(def-de-split 1163700 1576150) ;; 一人で

(def-de-split 1611020 1577100) ;; 何で

(def-de-split 1004800 1628530) ;; これで

(def-de-split 2810720 1004820) ;; 此れまでで

(def-de-split 1006840 1006880) ;; その上で

(def-de-split 1530610 1530600) ;; 無断で

(def-de-split 1245390 1245290) ;; 空で

(def-de-split 2719270 1445430) ;; 土足で

(def-de-split 1189420 2416780) ;; 何用で

(def-de-split 1263640 1630950) ;; 現行犯で

(def-de-split 1272220 1592990) ;; 交代で

(def-de-split 1311360 1311350) ;; 私費で

(def-de-split 1368500 1368490) ;; 人前で

(def-de-split 1395670 1395660) ;; 全体で

(def-de-split 1417790 1417780) ;; 単独で

(def-de-split 1454270 1454260) ;; 道理で

(def-de-split 1479100 1679020) ;; 半眼で

(def-de-split 1510140 1680900) ;; 別封で

(def-de-split 1510170 1510160) ;; 別便で

(def-de-split 1518550 1529560) ;; 無しで

(def-de-split 1531420 1531410) ;; 名義で

(def-de-split 1597400 1585205) ;; 力尽くで

(def-de-split 1679990 2582460) ;; 抜き足で

(def-de-split 1682060 2085340) ;; 金ずくで

(def-de-split 1736650 1611710) ;; 水入らずで

(def-de-split 1865020 1590150) ;; 陰で

(def-de-split 1878880 2423450) ;; 差しで

(def-de-split 2126220 1802920) ;; 捩じり鉢巻きで

(def-de-split 2136520 2005870) ;; もう少しで

(def-de-split 2276140 1188520) ;; 何やかやで

(def-de-split 2513590 2513650) ;; 詰め開きで

(def-de-split 2771850 2563780) ;; 気にしないで

(def-de-split 2810800 1587590) ;; 今までで

(def-de-split 1343110 1343100) ;; ところで

(def-simple-split split-degozaimasu 2253080 20 () ;; でございます
  (2028980 1)
  (1612690 nil t))

(defmacro def-toori-split (seq seq-a &key (score 50) (seq-b 1432930))
  (let ((name (intern (format nil "~a~a" :split-toori- seq))))
    `(def-simple-split ,name ,seq ,score (len txt r)
       (:test (eql (word-type r) :kanji))
       (,seq-a (- len 2))
       (,seq-b 2))))

(def-toori-split 1260990 1260670) ;; 元通り

(def-toori-split 1414570 2082450) ;; 大通り

(def-toori-split 1424950 1620400) ;; 中通り [ちゅう通り]
(def-toori-split 1424960 1423310) ;; 中通り [なか通り]

(def-toori-split 1820790 1250090) ;; 型通り

(def-toori-split 1489800 1489340) ;; 表通り

(def-toori-split 1523010 1522150) ;; 本通り

(def-toori-split 1808080 1604890) ;; 目通り

(def-toori-split 1368820 1580640) ;; 人通り

(def-toori-split 1550490 1550190) ;; 裏通り

(def-toori-split 1619440 2069220) ;; 素通り

(def-toori-split 1164910 2821500 :seq-b 1432920) ;; 一通り

(def-toori-split 1462720 1461140 :seq-b 1432920) ;; 二通り

(defmacro def-do-split (seq seq-b &key (score 30) (seq-a 2252690))
  (let ((name (intern (format nil "~a~a" :split-do- seq))))
    `(def-simple-split ,name ,seq ,score (len txt r)
       (,seq-a 1)
       (,seq-b))))

(def-do-split 2142710 1185200) ;; ど下手

(def-do-split 2803190 1595630) ;; どすけべ

(def-do-split 2142680 1290210) ;; ど根性

(def-do-split 2523480 1442750) ;; ど田舎

#|
(query (:select 'kt.seq 'kt.text
                :from (:as 'kanji-text 'kt) (:as 'sense-prop 'sp)
                :where (:and (:like 'kt.text "し%")
                             (:= 'sp.seq 'kt.seq) (:= 'sp.tag "pos")
                             (:in 'sp.text (:set *pos-with-conj-rules*)))))
|#

(defmacro def-shi-split (seq seq-b &key (score 30) (seq-a '("し" 1157170)))
  (let ((name (intern (format nil "~a~a" :split-shi- seq))))
    `(def-simple-split ,name ,seq ,score (len txt r)
       (,seq-a 1)
       (,seq-b nil t))))

(def-shi-split 1005700 1156990) ;; し易い
(def-shi-split 1005830 1370760) ;; し吹く
(def-shi-split 1157200 2772730) ;; し難い
(def-shi-split 1157220 1195970) ;; し過ぎる
(def-shi-split 1157230 1284430) ;; し合う
(def-shi-split 1157280 1370090) ;; し尽す
(def-shi-split 1157310 1405800) ;; し続ける
(def-shi-split 1304890 1256520) ;; し兼ねる
(def-shi-split 1304960 1307550) ;; し始める
(def-shi-split 1305110 1338180) ;; し出す
(def-shi-split 1305280 1599390) ;; し直す
(def-shi-split 1305290 1212670) ;; し慣れる
(def-shi-split 1594300 1596510) ;; し損なう
(def-shi-split 1594310 1406680) ;; し損じる
(def-shi-split 1594460 1372620) ;; し遂げる
(def-shi-split 1594580 1277100) ;; し向ける
(def-shi-split 2518250 1332760) ;; し終える

;; nakunaru split: because naku often attaches to previous word

(def-simple-split split-nakunaru 1529550 30 (len) ;; 無くなる
  (("無く" 1529520) 2)
  (1375610 nil t))

(def-simple-split split-nakunaru2 1518540 10 (len txt r) ;; 亡くなる
  (:test (eql (word-type r) :kana))
  (("亡く" 1518450) 2)
  (1375610 nil t))

;; tegakakaru split (kana form might conflict with other uses of kakaru verb)

(def-simple-split split-tegakakaru 2089710 10 (len) ;; 手が掛かる
  (1327190 1) ;; 手
  (2028930 1) ;; が
  (1207590 nil t))


(def-simple-split split-kawaribae 1411570 10 (len txt) ;; 代わり映え
  ((1590770 1510720) (1+ (position #\り txt)))
  (1600610 2 nil t))

(def-simple-split split-hayaimonode 2815260 100 (len txt) ;; 早いもので
  (1404975 (1+ (position #\い txt)))
  (1502390 (if (find #\物 txt) 1 2))
  (2028980 1))

(def-simple-split split-dogatsukeru 2800540 30 (len) ;; ドが付ける
  (2252690 1)
  (2028930 1)
  (1495740 nil t))

(def-simple-split split-janaika 2819990 20 (len) ;; じゃないか
  (("じゃない" 2089020) 4)
  (2028970 1))

(def-simple-split split-kaasan 1609470 50 (len txt r) ;; 母さん
  (:test (eql (word-type r) :kanji))
  (1514990 1)
  (1005340 2))

(def-simple-split split-souda 1006650 5 ()
  (2137720 2)
  ((2089020 1628500)))

(def-simple-split split-kinosei 1221750 100 ()
  (1221520 1)
  (1469800 1)
  (1610040 2))

(def-simple-split split-kigatsuku 1591050 100 ()
  (1221520 1)
  (2028930 1)
  (1495740 nil t))

(def-simple-split split-nanimokamo 1599590 20 (len) ;; なにもかも
  (1188490 (- len 2))
  (2143350 2))

(def-simple-split split-katawonaraberu 2102910 20 (len txt) ;; 肩を並べる
  (1258950 (position #\を txt))
  (2029010 1)
  (1508390 nil t))

(def-simple-split split-moushiwakenasasou 2057340 300 (len txt) ;; 申し訳なさそう
  (1363050 (position #\な txt))
  (2246510))

(def-simple-split split-kimatte 1951150 50 () ;; 決まって
  (("決まって" 1591420)))

(def-simple-split split-osoreiru 1236680 100 (len txt) ;; 恐れ入る
  (1236660 (1+ (position #\れ txt)))
  (1465580 nil t))

(def-simple-split split-nantokanaru 2104540 20 (len txt) ;; なんとかなる
  (1188420 (1+ (position #\か txt)))
  (1375610 nil t))

(def-simple-split split-hajiketobu 2610760 50 (len txt) ;; 弾け飛ぶ
  (("弾け" 1419380) (1+ (position #\け txt)))
  (1429700 nil t))

(def-simple-split split-motteiku 1315700 50 (len txt) ;; 持って行く
  (("持って" 1315720) (1+ (position #\て txt)))
  (1578850 nil t))

(def-simple-split split-hairikomeru 1465460 100 (len txt r) ;; 入り込める
  (:test (eql (word-type r) :kanji))
  (("入り" 1465590) (1+ (position #\り txt)))
  (1288790 nil t))

(def-simple-split split-shinikakaru 1881080 30 () ;;死に掛かる
  (1310720 1)
  (2028990 1)
  (1207590 nil t))

(def-simple-split split-hisshininatte 1903910 50 (len txt) ;;必死になって
  (1601890 (position #\に txt))
  (2028990 1)
  (("なって" 1375610) nil))

(def-simple-split split-hitogayoi 2827409 30 (len txt) ;;人が好い
  (1580640 (position #\が txt))
  (2028930 1)
  (1605820 nil t))

(def-simple-split split-nitotte 1009600 50 (len txt) ;; にとって
  (2028990 1)
  (("取って" 1326980)))

(def-simple-split split-kotonisuru 2215340 100 (len txt) ;; 事にする
  (1313580 (position #\に txt))
  (2028990 1)
  (1157170 nil t))

(def-simple-split split-hajikidasu 1419350 100 (len txt) ;; 弾き出す
  (1901710 (1+ (position #\き txt)))
  (1338180 nil t))

(def-simple-split split-hitotachi 1368740 100 (len txt) ;; 人たち
  (1580640 (if (position #\人 txt) 1 2))
  (1416220 (if (position #\達 txt) 1 2)))

(def-simple-split split-desura 2034520 30 (len txt) ;; でさえ ですら
  (2028980 1)
  ((2827091))) ;; 1005120

(def-simple-split split-gotoni 1524660 50 (len txt) ;; ごとに
  (1524640 (position #\に txt))
  (2028990 1))

(def-simple-split split-osagari 1693800 50 () ;; お下がり
  (2826528 1)
  (1609810))

(def-simple-split split-kaisasae 1752860 50 () ;; 買い支え
  (1636070 2)
  (("支え" 1310090)))

(def-simple-split split-toiukotoda 2612990 30 (len) ;; ということだ
  (1922760 3)
  (1313580 (- len 4))
  (2089020))

(def-simple-split split-tonattara 2100770 50 (len) ;; となったら
  (1008490 1)
  (("なったら" 1375610)))

(def-simple-split split-tonaru 2100900 10 (len) ;; となる
  (1008490 1)
  (1375610 nil t))

(def-simple-split nil 1327220 50 (len) ;; 手に入る
  (1327190 1)
  (2028990 1)
  (1465590 nil t))

(def-simple-split nil 2433760 50 (len) ;; そうなんです
  (1006610 2)
  (2683060))

(def-simple-split nil 2088480 20 (len) ;; 良さげ
  (1634130 2)
  (2006580 1))

(def-simple-split nil 2724560 30 (len) ;; のせいで
  (1469800 1)
  (1610040 (- len 2))
  (2028980 1))

(def-simple-split nil 2666360 30 () ;; 少なくない
  (("少なくない" 1348910)))

(def-simple-split split-janai 2755350 10 (len) ;; じゃない
  (2089020 2)
  (2906771 nil t))

;; SEGMENT SPLITS (allows to expand one segment into several, e.g. "ところが" "ところ+が")

(defparameter *segsplit-map* (make-hash-table)) ;; seq -> split function

(let ((*split-map* *segsplit-map*))
  (def-simple-split split-tokoroga 1008570 '(-10) (len) ;; ところが
    (1343100 (- len 1))
    (2028930 1))

  (def-simple-split split-tokorode 1343110 '(-10 :root (1)) (len) ;; ところで
    (1343100 (- len 1))
    (2028980 1))

  (def-simple-split split-dokoroka 2009220 '(-10) (len) ;; 所か
    (1343100 (- len 1))
    (2028970 1))

  (def-simple-split split-tokoroe 2097010 '(-10) (len) ;; ところへ
    (1343100 (- len 1))
    (2029000 1))

  (def-simple-split split-tokorowo 2136660 '(-10) (len) ;; ところを
    (1343100 (- len 1))
    (2029010 1))

  (def-simple-split split-omise 2409240 '(20 :primary 1 :connector "") (len) ;; お店
    (2826528 1)
    (1582120))

  (def-simple-split split-hitorashii 1366490 '(-10 :connector "") (len) ;; 人らしい
    (1580640 (- len 3))
    (1013240))

  (def-simple-split split-toha 2028950 '(-5) (len) ;; とは
    (1008490 1)
    (2028920 1))

  (def-simple-split split-deha 1008450 '(-5) (len) ;; では
    (2028980 1)
    (2028920 1))

  (def-simple-split split-naito 2394710 '(-5) (len) ;; ないと
    (1529520 2)
    (1008490 1))

  (def-simple-split split-honno 1011740 '(-5) (len) ;; ほんの
    (1522150 (- len 1))
    (1469800 1))

  (def-simple-split split-kanatte 1208870 '(5) (len txt) ;; かなって
    (:test (equal txt "かなって"))
    (1002940 2)
    (2086960 2))
  )

(defun get-segsplit (segment &aux (word (segment-word segment)))
  (when (typep word 'simple-text)
    (let ((*split-map* *segsplit-map*))
      (multiple-value-bind (split attrs)
          (get-split word (cdr (getf (segment-info segment) :seq-set)))
        (when split
          (destructuring-bind (score &key (primary 0) (connector " ") root) attrs
            (let* ((word
                    (make-instance 'compound-text
                                   :text (str:join "" (mapcar 'get-text split))
                                   :kana (str:join connector (mapcar 'get-kana split))
                                   :primary (elt split primary)
                                   :words split
                                   :score-mod score))
                   (new-seg (copy-segment segment)))
              (when root
                (loop for i from 0 for word in split
                   if (find i root) do (setf (word-conjugations word) :root)))
              (setf (segment-word new-seg) word
                    (segment-text new-seg) (get-text word)
                    (segment-score new-seg) (+ (segment-score segment) score))
              new-seg)))))))


;; KANA HINTS (indicate when to romanize は as わ etc.)

(defparameter *kana-hint-mod* #\u200c)
(defparameter *kana-hint-space* #\u200b)

(defparameter *hint-char-map* `(:space ,*kana-hint-space* :mod ,*kana-hint-mod*))

(defparameter *hint-simplify-map*
  (list (string *kana-hint-space*) " "
        (coerce (list *kana-hint-mod* #\は) 'string) "わ"
        (coerce (list *kana-hint-mod* #\ハ) 'string) "ワ"
        (coerce (list *kana-hint-mod* #\へ) 'string) "え"
        (coerce (list *kana-hint-mod* #\ヘ) 'string) "エ"
        (string *kana-hint-mod*) ""))

(defun process-hints (word)
  (simplify-ngrams word *hint-simplify-map*))

(defun strip-hints (word)
  (remove-if (lambda (c) (find c *hint-char-map*)) word))

(defparameter *kana-hint-map* (make-hash-table)) ;; seq -> split function

(defun insert-hints (str hints &aux (len (length str)))
  ;; hints are ((character-kw position) ...)
  (unless hints
    (return-from insert-hints str))
  (let ((positions (make-array (1+ len) :initial-element nil)))
    (loop for (character-kw position) in hints
       for char = (getf *hint-char-map* character-kw)
       when (<= 0 position len)
       do (push char (aref positions position)))
    (with-output-to-string (s)
      (loop for i from 0 upto len
         do (loop for char in (reverse (aref positions i))
               do (write-char char s))
         when (< i len)
         do (write-char (char str i) s)))))

(defparameter *hint-map* (make-hash-table)) ;; seq -> hint function

(defmacro defhint (seqs (reading-var) &body body)
  (unless (listp seqs)
    (setf seqs (list seqs)))
  (alexandria:with-gensyms (fn)
    `(let ((,fn (lambda (,reading-var) ,@body)))
       ,@(loop for seq in seqs
            collect `(setf (gethash ,seq *hint-map*) ,fn)))))

(defmacro def-simple-hint (seqs (&optional length-var kana-var reading-var) &body hints-def
                           &aux test-var test-var-used)
  (unless reading-var (setf reading-var (gensym "RV")))
  (unless length-var (setf length-var (gensym "LV")))
  (unless kana-var (setf kana-var (gensym "KV")))
  (setf test-var (gensym "TV"))
  `(defhint ,seqs (,reading-var)
     (block hint
       (let* ((,kana-var (true-kana ,reading-var))
              (,length-var (length ,kana-var))
              ,@(loop for (var value) in hints-def
                     for tvar = (cond ((eql var :test) (setf test-var-used t) test-var)
                                      ((keywordp var) nil)
                                      (t var))
                     when tvar collect `(,tvar (or ,value (return-from hint nil)))))
         (declare (ignorable ,length-var ,@(when test-var-used (list test-var))))
         (insert-hints (get-kana ,reading-var)
                       (list
                        ,@(loop for pair in hints-def
                             when (and (keywordp (car pair)) (not (eql (car pair) :test)))
                             collect `(list ,@pair))))))))

(defun translate-hint-position (match position)
  (loop with off = 0 and rem = position
     for part in match
     do (if (atom part)
            (let ((len (length part)))
              (cond
                ((<= rem len) (return (+ off rem)))
                (t (decf rem len) (incf off len))))
            (let ((len (length (first part)))
                  (clen (length (second part))))
              (cond
                ((< rem len)
                 (return (+ off (min 1 (max clen rem)))))
                ((= rem len)
                 (return (+ off clen)))
                (t (decf rem len) (incf off clen)))))))

(defun translate-hints (match hints)
  (loop for (hint pos) in hints
     for new-pos = (translate-hint-position match pos)
     if new-pos collect (list hint new-pos)))

(defmacro def-easy-hint (seq kanji-split)
  (let* ((parts (split-sequence #\Space kanji-split))
         (text (remove #\Space kanji-split))
         (hints (loop with pos = 0
                   for part in parts
                   unless (zerop pos)
                   collect (list :space pos)
                   and if (find part '("は" "へ" "には" "とは") :test 'equal)
                       collect (list :mod (+ pos (length part) -1))
                   do (incf pos (length part))))
         (reading-var (gensym "RV")))
    (alexandria:with-gensyms (match kr rtext)
      `(defhint (,seq) (,reading-var)
         (when (typep ,reading-var 'simple-text)
           (let* ((,rtext (true-kanji ,reading-var))
                  (,match (match-diff ,text ,rtext))
                  (,kr (ichiran/kanji:match-readings ,rtext (true-kana ,reading-var))))
             (when (and ,match ,kr)
               (insert-hints (get-kana ,reading-var) (translate-hints ,kr (translate-hints ,match ',hints))))))))))

(defun get-hint (reading)
  (let ((hint-fn (gethash (seq reading) *hint-map*))
        (conj-of (mapcar #'conj-data-from (word-conj-data reading))))
    (if hint-fn
        (funcall hint-fn reading)
        (loop for seq in conj-of
           for hint-fn = (gethash seq *hint-map*)
           when hint-fn do (return (funcall hint-fn reading))))))

;; expressions ending with は

#|
(query (:select 'kt.seq 'kt.text :from (:as 'kana-text 'kt) (:as 'sense-prop 'sp)
                              :where (:and (:= 'kt.seq 'sp.seq)
                                           (:= 'sp.tag "pos")
                                           (:= 'sp.text "exp")
                                           (:like 'kt.text "%は")
                                           (:not (:in 'kt.seq (:set (alexandria:hash-table-keys *hint-map*)))))))


(:select 'kt.seq 'kt.text :from (:as 'kanji-text 'kt) (:as 'sense-prop 'sp)
                              :where (:and (:= 'kt.seq 'sp.seq)
                                           (:= 'sp.tag "pos")
                                           (:= 'sp.text "exp")
                                           (:like 'kt.text "%は%")
                                           (:not (:in 'kt.seq (:set (alexandria:hash-table-keys *hint-map*))))))
|#

;; TODO pos=int, pos=adv

(def-simple-hint
    (2028920 ;; は
     2029000 ;; へ
     )
    (l)
  (:mod (- l 1)))

(def-simple-hint ;; no space
    (1289480 ;; こんばんは
     1289400 ;; こんにちは
     1004620 ;; こにちは
     1008450 ;; では
     2215430 ;; には
     2028950 ;; とは
     )
    (l k)
  (:test (alexandria:ends-with #\は k))
  (:mod (- l 1)))

(def-simple-hint ;; with space
    (1006660 ;; そうでないばあいは
     1008500 ;; というのは
     1307530 ;; はじめは
     1320830 ;; じつは
     1324320 ;; もしくは
     1524990 ;; または
     1586850 ;; あるいは
     1586850 ;; あるは
     1877880 ;; ごきぼうのむきは
     1897510 ;; ところでは
     1907300 ;; へいそは
     1912570 ;; もとは
     2034440 ;; にかけては
     2098160 ;; なくては
     2105820 ;; にしては
     2134680 ;; それは
     2136300 ;; ということは
     2173060 ;; それいがいのものは
     2176280 ;; これは
     2177410 ;; のぞむらくは
     2177420 ;; おそらくは
     2177430 ;; おしむらくは
     2177440 ;; うらむらくは
     2177450 ;; こいねがわくは
     2256430 ;; としては
     2428890 ;; さすがは
     2523450 ;; おかれましては
     2557290 ;; なんだこれは
     2629620 ;; だけは
     2673120 ;; かくなるうえは
     2691570 ;; あいなるべくは
     2702090 ;; ては
     2717440 ;; ずは
     2717510 ;; ってのは
     2828541 ;; あさのは
     2176280 ;; これは
     1217970 ;; 希わくは
     1260080 ;; 見方によっては
     1263700 ;; 現時点においては
     1331520 ;; 就きましては
     1907290 ;; 平生は
     1914670 ;; 要は
     1950430 ;; 果ては
     2136680 ;; 無くしては
     2181810 ;; 上は
     2181730 ;; 然上は
     1217970 ;; 願わくは
     2181730 ;; 然る上は
     2576840 ;; 何時かは
     2181730 ;; しかる上は
     1331510 ;; 就いては
     1010470 ;; 延いては
     2008290 ;; さては
     2136690 ;; にあっては
     2829815 ;; まずは
     2830216 ;; じっさいは
     )
    (l k)
  (:test (alexandria:ends-with #\は k))
  (:space (- l 1))
  (:mod (- l 1)))

(def-simple-hint
    (2097010 ;; ところへ
     )
    (l)
  (:mod (- l 1)))

(def-simple-hint
    (2261800 ;; それはそれは
     )
    (l)
  (:space 2)
  (:mod 2)
  (:space 3)
  (:space (- l 1))
  (:mod (- l 1)))

(def-simple-hint ;; では/には ending
    (1009480 ;; ならでは
     1315860 ;; ときには
     1406050 ;; それでは
     1550170 ;; りろんてきには
     1917520 ;; わたくしなどには
     1917530 ;; わたくしのほうでは
     2026610 ;; からには
     2061740 ;; みたかぎりでは
     2097310 ;; ただでは
     2101020 ;; あるいみでは
     2119920 ;; そのわりには
     2134700 ;; なしには
     2200100 ;; うえでは
     2407650 ;; このぶんでは
     2553140 ;; こんにちでは
     2762790 ;; ひとつには
     1288910 ;; いまでは
     1423320 ;; なかにわ
     2099850 ;; ないことには
     1006890 ;; そのばあいには
     1887540 ;; 成功の暁には
     )
    (l k)
  (:test (alexandria:ends-with #\は k))
  (:space (- l 2))
  (:mod (- l 1)))

;; では expressions

(def-simple-hint
    (2089020 ;; だ
     2823770 ;; ではない
     2098240 ;; ではある
     2027020 ;; ではないか
     2135480 ;; ではまた
     2397760 ;; ではありますまいか
     2724540 ;; ではなかろうか
     2757720 ;; ではなさそう
     )
    (l k)
  (deha (search "では" k :from-end t))
  (:mod (1+ deha)))

(def-simple-hint ;; ends with ではない
    (1922645 ;; ふつうではない
     2027080 ;; べきではない
     2118000 ;; ひとごとではない
     2126160 ;; どうじつのだんではない
     2126140 ;; でるまくではない
     2131120 ;; たいしたことではない
     2136640 ;; といってもかごんではない
     2214830 ;; すてたものではない
     2221680 ;; いわないことではない
     2416950 ;; ばかりがのうではない
     2419210 ;; どうじつのろんではない
     2664520 ;; たまったものではない
     2682500 ;; しょうきのさたではない
     2775790 ;; それどころではない
     1343120 ;; どころではない
     1012260 ;; まんざらゆめではない
     2112270 ;; もののかずではない
     2404260 ;; しったことではない
     2758400 ;; みられたものではない
     2827556 ;; だけがのうではない
     2057560 ;; わけではない
     2088970 ;; しないのではないか
     2088970 ;; ないのではないか
     2833095 ;; 吝かではない
     2835662 ;; 地獄にも鬼ばかりではない
     )
    (l k)
  (deha (search "では" k :from-end t))
  (:space deha)
  (:mod (1+ deha)))

;; では in the middle
(def-simple-hint
    (2037860 ;; ただではおかないぞ
     2694350 ;; ころんでもただではおきない
     2111220 ;; ひとすじなわではいかない
     2694360 ;; ころんでもただではおきぬ
     2182700 ;; ないではいられない
     2142010 ;; 口では大阪の城も建つ
     )
    (l k)
  (deha (search "では" k :from-end t))
  (:space deha)
  (:mod (1+ deha))
  (:space (+ 2 deha)))

;; には in the middle
(def-simple-hint
    (2057580 ;; わけにはいかない
     2067990 ;; つうにはたまらない
     2103020 ;; かわいいこにはたびをさせよ
     2105980 ;; てきをあざむくにはまずみかたから
     2152700 ;; わらうかどにはふくきたる
     2416920 ;; なくことじとうにはかてぬ
     2418030 ;; うえにはうえがある
     2792210 ;; れいにはおよばない
     2792420 ;; おれいにはおよびません
     2417920 ;; おんなのかみのけにはたいぞうもつながる
     2598720 ;; せきぜんのいえにはかならずよけいあり
     2420170 ;; きれいなばらにはとげがある
     2597190 ;; わけにはいけない
     2597800 ;; せきふぜんのいえにはかならずよおうあり
     2057570 ;; わけにはいきません
     2419360 ;; ねんにはねんをいれよ
     2121480 ;; うらにはうらがある
     2646440 ;; のこりものにはふくがある
     2740880 ;; なくことじとうにはかてない
     2416860 ;; よるとしなみにはかてない
     2156910 ;; ひとのくちにはとがたてられない
     2182690 ;; ずにはいられない looks like a suffix?
     )
    (l k)
  (niha (search "には" k :from-end t))
  (:space niha)
  (:mod (1+ niha))
  (:space (+ 2 niha)))

;; starts with には/とは

(def-simple-hint
    (2181860 ;; にはおよばない
     2037320 ;; とはいえ
     2125460 ;; とはべつに
     2128060 ;; とはいうものの
     2070730 ;; とはかぎらない
     )
    (l k)
  (:mod 1)
  (:space 2))

(def-simple-hint
    (2832044 ;; 目には目を
     )
    (l k)
  (niha (search "には" k :from-end t))
  (:space niha)
  (:mod (1+ niha))
  (:space (+ 2 niha))
  (:space (- l 1)))

;; は in the middle
(def-simple-hint
    (1008970 ;; "どうってことはない" "どうってことはない")
     1188440 ;; "何とはなしに" "なんとはなしに")
     1193090 ;; "果報は寝て待て" "かほうはねてまて")
     1394290 ;; "善は急げ" "ぜんはいそげ")
     1855940 ;; "挨拶は抜きで" "あいさつはぬきで")
     1900670 ;; "根はおとなしい" "ねはおとなしい")
     1949380 ;; "無理はない" "むりはない")
     1981600 ;; "一寸先は闇" "いっすんさきはやみ")
     1982230 ;; "其れはそうと" "それはそうと")
     2018320 ;; "無いよりはまし" "ないよりはまし")
     2062980 ;; "ありゃしない" "ありゃしない")
     2078930 ;; "賽は投げられた" "さいはなげられた")
     2089520 ;; "それはどうも" "それはどうも")
     2089620 ;; "それはさておき" "それはさておき")
     2098150 ;; "無くてはならない" "なくてはならない")
     2108910 ;; "かたいことは言いっこなし" "かたいことはいいっこなし")
     2115570 ;; "それはどうかな" "それはどうかな")
     2118120 ;; "何はさておき" "なにはさておき")
     2118430 ;; "何はともあれ" "なにはともあれ")
     2118440 ;; "何は無くとも" "なにはなくとも")
     2134480 ;; "恋は盲目" "こいはもうもく")
     2135530 ;; "ほどの事はない" "ほどのことはない")
     2136710 ;; "と言うことはない" "ということはない")
     2141360 ;; "気は心" "きはこころ")
     2168360 ;; "多芸は無芸" "たげいはむげい")
     2173880 ;; "今は昔" "いまはむかし")
     2174570 ;; "如くは無し" "しくはなし")
     2176450 ;; "今はこれまで" "いまはこれまで")
     2177240 ;; "宝は湧き物" "たからはわきもの")
     2200690 ;; "子は鎹" "こはかすがい")
     2210960 ;; "勝ち目はない" "かちめはない")
     2213470 ;; "それはそれで" "それはそれで")
     2255320 ;; "無くてはいけない" "なくてはいけない")
     2275900 ;; "ものは言いよう" "ものはいいよう")
     2403520 ;; "どうという事はない" "どうということはない")
     2408680 ;; "来る者は拒まず" "くるものはこばまず")
     2416870 ;; "気は持ちよう" "きはもちよう")
     2416930 ;; "去る者は追わず" "さるものはおわず")
     2417040 ;; "金銀は回り持ち" "きんぎんはまわりもち")
     2417150 ;; "血は争えない" "ちはあらそえない")
     2417980 ;; "小事は大事" "しょうじはだいじ")
     2418090 ;; "寝る子は育つ" "ねるこはそだつ")
     2418280 ;; "人は情け" "ひとはなさけ")
     2418800 ;; "その時はその時" "そのときはそのとき")
     2418840 ;; "待つ身は長い" "まつみはながい")
     2418920 ;; "短気は損気" "たんきはそんき")
     2419030 ;; "長所は短所" "ちょうしょはたんしょ")
     2419350 ;; "年は争えない" "としはあらそえない")
     2419390 ;; "馬は馬連れ" "うまはうまづれ")
     2419590 ;; "ものは考えよう" "ものはかんがえよう")
     2419600 ;; "物は使いよう" "ものはつかいよう")
     2419610 ;; "物は試し" "ものはためし")
     2419620 ;; "ものは相談" "ものはそうだん")
     2420180 ;; "餠は餠屋" "もちはもちや")
     2583560 ;; "切っては切れない" "きってはきれない")
     2585230 ;; "事はない" "ことはない")
     2593830 ;; "其れはそうとして" "それはそうとして")
     2600530 ;; "其とはなしに" "それとはなしに")
     2618920 ;; "生き身は死に身" "いきみはしにみ")
     2618990 ;; "無知は幸福" "むちはこうふく")
     2708230 ;; "何のことはない" "なんのことはない")
     2716900 ;; "そうは行かない" "そうはいかない")
     2737650 ;; "油断は禁物" "ゆだんはきんもつ")
     2741810 ;; "いい後は悪い" "いいあとはわるい")
     2744840 ;; "様はない" "ざまはない")
     2747300 ;; "タダ飯はない" "タダめしはない")
     2827424 ;; "気はさらさらない" "きはさらさらない")
     2827754 ;; "男は黙って" "おとこはだまって")
     2831359 ;; "無くてはいけません" "なくてはいけません")
     2833597 ;; "君子は豹変す" "くんしはひょうへんす")
     )
    (l k)
  (ha (search "は" k :from-end t))
  (:space ha)
  (:mod ha)
  (:space (1+ ha)))


;; Easy hints!

;; は

(def-easy-hint 1238480 "郷 に 入って は 郷 に 従え")
(def-easy-hint 1338260 "出る 釘 は 打たれる")
(def-easy-hint 1471680 "馬鹿 は 死ななきゃ 治らない")
(def-easy-hint 1566340 "屁 と 火事 は もと から 騒ぐ")
(def-easy-hint 1638390 "用心する に 如く は ない")
(def-easy-hint 1985430 "出る 杭 は 打たれる")
(def-easy-hint 2078950 "背 に 腹 は かえられない")
(def-easy-hint 2083430 "瓜 の 蔓 に 茄子 は ならぬ")
(def-easy-hint 2089750 "何か いい手 は ない か")
(def-easy-hint 2093380 "敵 は 本能寺 に あり")
(def-easy-hint 2101500 "無い 袖 は 振れぬ")
(def-easy-hint 2109530 "継続 は 力 なり")
(def-easy-hint 2111700 "事実 は 小説 より 奇 なり")
(def-easy-hint 2111710 "事実 は 小説 よりも 奇 なり")
(def-easy-hint 2113730 "縁 は 異なもの 味なもの")
(def-easy-hint 2113740 "縁は異なもの")
(def-easy-hint 2125770 "その手 は 食わない")
(def-easy-hint 2130410 "すまじき もの は 宮仕え")
(def-easy-hint 2140350 "時 は 金 なり")
(def-easy-hint 2140990 "青 は 藍 より 出でて 藍 より 青し")
(def-easy-hint 2152710 "渡る 世間 に 鬼 は ない")
(def-easy-hint 2152850 "病 は 気 から")
(def-easy-hint 2152960 "甲 の 薬 は 乙 の 毒")
(def-easy-hint 2159970 "好奇心 は 猫 をも 殺す")
(def-easy-hint 2159990 "甘い物 は 別腹")
(def-easy-hint 2168350 "ペン は 剣 よりも 強し")
(def-easy-hint 2176630 "千金 の 裘 は 一狐 の 腋 に 非ず")
(def-easy-hint 2177220 "宝 さかって 入る 時 は さかって 出る")
(def-easy-hint 2178680 "出す こと は 舌を出す も 嫌い")
(def-easy-hint 2195810 "に 越した こと は ない")
(def-easy-hint 2209690 "男 に 二言 は ない")
(def-easy-hint 2216540 "背 に 腹 は 替えられぬ")
(def-easy-hint 2219580 "寝言 は 寝て から 言え")
(def-easy-hint 2411180 "用心する に 越した こと は ない")
(def-easy-hint 2416580 "悪い 事 は 出来ぬ もの")
(def-easy-hint 2416650 "衣 ばかり で 和尚 は できぬ")
(def-easy-hint 2416680 "一銭 を 笑う 者 は 一銭 に 泣く")
(def-easy-hint 2417140 "血 は 水 よりも 濃い")
(def-easy-hint 2417180 "見る と 聞く とは 大違い")
(def-easy-hint 2417270 "後 は 野となれ 山となれ")
(def-easy-hint 2417540 "昨日 の 友 は 今日 の 敵")
(def-easy-hint 2417580 "山椒 は 小粒 でも ぴりりと 辛い")
(def-easy-hint 2417750 "蒔かぬ 種 は 生えぬ")
(def-easy-hint 2417760 "鹿 を 追う 者 は 山 を 見ず")
(def-easy-hint 2418060 "色事 は 思案 の 外")
(def-easy-hint 2418100 "寝る ほど 楽 は なかりけり")
(def-easy-hint 2418220 "人 の 口 に 戸 は 立てられず")
(def-easy-hint 2418250 "人 は パン のみ にて 生くる 者 に 非ず")
(def-easy-hint 2418270 "人 は 見かけ に よらぬ もの")
(def-easy-hint 2418490 "世間 の 口 に 戸 は 立てられぬ")
(def-easy-hint 2418500 "世間 は 広い 様 で 狭い")
(def-easy-hint 2418600 "生ある 者 は 必ず 死あり")
(def-easy-hint 2418700 "栴檀 は 双葉 より 芳し")
(def-easy-hint 2418720 "前車 の 覆る は 後車 の 戒め")
(def-easy-hint 2418900 "タダ より 高い もの は ない")
(def-easy-hint 2418970 "知らぬ は 亭主 ばかり なり")
(def-easy-hint 2419060 "釣り落とした 魚 は 大きい")
(def-easy-hint 2419120 "転んでも ただ は 起きぬ")
(def-easy-hint 2419190 "逃がした 魚 は 大きい")
(def-easy-hint 2419260 "二兎 を 追う 者 は 一兎 をも 得ず")
(def-easy-hint 2419270 "二度ある こと は 三度ある")
(def-easy-hint 2419410 "馬鹿 と はさみ は 使いよう")
(def-easy-hint 2419420 "馬鹿 に つける 薬 は ない")
(def-easy-hint 2419450 "板子 一枚 下 は 地獄")
(def-easy-hint 2419530 "夫婦喧嘩 は 犬 も 食わない")
(def-easy-hint 2419690 "文 は 人 なり")
(def-easy-hint 2419710 "聞く と 見る とは 大違い")
(def-easy-hint 2419730 "便り の ない の は よい 便り")
(def-easy-hint 2419800 "名の無い 星 は 宵 から 出る")
(def-easy-hint 2419970 "余 の 辞書 に 不可能 という 文字 は ない")
(def-easy-hint 2420010 "用心 に 越した こと は ない")
(def-easy-hint 2420110 "例外のない規則はない")
(def-easy-hint 2420120 "歴史は繰り返す")
(def-easy-hint 2420190 "驕る平家は久しからず")
(def-easy-hint 2424500 "目的のためには手段を選ばない")
(def-easy-hint 2442180 "命に別条はない")
(def-easy-hint 2570900 "藁 で 束ねても 男 は 男")
(def-easy-hint 2580730 "知 は 力 なり")
(def-easy-hint 2582770 "既往 は 咎めず")
(def-easy-hint 2641030 "相手 にとって 不足 は ない")
(def-easy-hint 2670900 "お世辞 にも うまい とは 言えない")
(def-easy-hint 2694370 "転んでも ただ は 起きない")
(def-easy-hint 2738830 "お客様 は 神様 です")
(def-easy-hint 2757560 "宵越し の 銭 は 持たない")
(def-easy-hint 2758920 "立っている もの は 親 でも 使え")
(def-easy-hint 2761670 "先 の こと は 分からない")
(def-easy-hint 2776820 "理屈 と 膏薬 は どこ へ でも つく")
(def-easy-hint 2783090 "疑わしき は 罰せず")
(def-easy-hint 2784400 "蟹 は 甲羅 に 似せて 穴 を 掘る")
(def-easy-hint 2789240 "嘘 と 坊主 の 頭 は ゆった ことがない")
(def-easy-hint 2792090 "正気 とは 思えない")
(def-easy-hint 2797740 "一円 を 笑う 者 は 一円 に 泣く")
(def-easy-hint 2798610 "お神酒 上がらぬ 神 は ない")
(def-easy-hint 2826812 "悪いことは言わない")
(def-easy-hint 2828308 "吐いた唾は飲めぬ")
(def-easy-hint 2830029 "明けない夜はない")
(def-easy-hint 2833956 "山より大きな猪は出ぬ")
(def-easy-hint 2833957 "老兵は死なずただ消え去るのみ")
(def-easy-hint 2833961 "梅は食うとも核食うな、中に天神寝てござる")
(def-easy-hint 2833986 "悪に強いは善にも強い")
(def-easy-hint 2108440 "過ちて は 則ち 改むる に 憚る こと 勿れ")
(def-easy-hint 2417420 "降り懸かる 火の粉 は 払わねば ならぬ")
(def-easy-hint 2418640 "静かに 流れる 川 は 深い")
(def-easy-hint 2835355 "無い 物 は 無い")
(def-easy-hint 2835504 "気 は 確か")
(def-easy-hint 2835673 "見る は 法楽")
(def-easy-hint 2836181 "持つべき もの は 友")
(def-easy-hint 2836183 "持つべき もの は 友人")
(def-easy-hint 2836500 "経験者 は 語る")

;; は は

(def-easy-hint 2416600 "悪人 は 畳 の 上 で は 死ねない")
(def-easy-hint 2767400 "鬼 は 外 福 は 内")
(def-easy-hint 2418260 "人 は 一代 名 は 末代")
(def-easy-hint 2828341 "花 は 桜木 人 は 武士")
(def-easy-hint 2086560 "鶴 は 千年 亀 は 万年")
(def-easy-hint 2152790 "楽 は 苦 の 種 苦 は 楽 の 種")
(def-easy-hint 2154700 "旅 は 道連れ 世 は 情け")
(def-easy-hint 2158840 "男 は 度胸 女 は 愛敬")
(def-easy-hint 2168380 "沈黙 は 金 雄弁 は 銀")
(def-easy-hint 2417120 "芸術 は 長く 人生 は 短し")
(def-easy-hint 2417230 "言う は 易く 行う は 難し")
(def-easy-hint 2417500 "今日 は 人の身 明日 は 我が身")
(def-easy-hint 2417930 "女 は 弱し されど 母 は 強し")
(def-easy-hint 2418180 "親 は 無くても 子 は 育つ")
(def-easy-hint 2418550 "生 は 難く 死 は 易し")
(def-easy-hint 2418630 "声 は すれども 姿 は 見えず")
(def-easy-hint 2418650 "昔 は 昔 今 は 今")
(def-easy-hint 2418740 "創業 は 易く 守成 は 難し")
(def-easy-hint 2419150 "東 は 東 西 は 西")
(def-easy-hint 2419950 "雄弁 は 銀 沈黙 は 金")
(def-easy-hint 2419960 "夕焼け は 晴れ 朝焼け は 雨")
(def-easy-hint 2420080 "旅 は 心 世 は 情け")
(def-easy-hint 2424520 "去る者 は 追わず 来たる者 は 拒まず")
(def-easy-hint 2558710 "遠き は 花 の 香 近き は 糞 の 香")
(def-easy-hint 2719710 "フグ は 食いたし 命 は 惜しし")
(def-easy-hint 2790690 "弓 は 袋 に 太刀 は 鞘")
(def-easy-hint 2828900 "山中 の 賊 を 破る は 易く 心中 の 賊 を 破る は 難し")
(def-easy-hint 2833976 "君子 は 周して 比せず 小人 は 比して 周せず")
(def-easy-hint 2833959 "知る者 は 言わず 言う者 は 知らず")
(def-easy-hint 2833900 "虎 は 死して 皮 を 留め 人 は 死して 名 を 残す")
(def-easy-hint 2570040 "朝焼け は 雨 夕焼け は 晴れ")
(def-easy-hint 2419570 "腹 が 減って は 戦 は 出来ぬ")
(def-easy-hint 2255410 "浜 の 真砂 は 尽きるとも 世 に 盗人 の 種 は 尽きまじ")
(def-easy-hint 2419720 "聞く は 一時 の 恥 聞かぬ は 末代 の 恥")
(def-easy-hint 2419910 "問う は 一旦 の 恥 問わぬ は 末代 の 恥")
(def-easy-hint 2757120 "問う は 一度 の 恥 問わぬ は 末代 の 恥")
(def-easy-hint 2834642 "柳 は 緑 花 は 紅")


;; には には

(def-easy-hint 2153170 "目 には 目 を 歯 には 歯 を")
(def-easy-hint 2422970 "人 には 添うて見よ 馬 には 乗って見よ")
(def-easy-hint 2833500 "馬 には 乗って見よ 人 には 添うて見よ")

;; の は

(def-easy-hint 1008660 "隣 の 芝生 は 青い")
(def-easy-hint 1204760 "蛙 の 子 は 蛙")
(def-easy-hint 2113380 "金 は 天下 の 回り物")
(def-easy-hint 2141020 "秋の日 は 釣瓶落とし")
(def-easy-hint 2144050 "秋 の 鹿 は 笛 に 寄る")
(def-easy-hint 2152870 "柳 の 下 に いつも 泥鰌 は おらぬ")
(def-easy-hint 2152930 "一年 の 計 は 元旦 に あり")
(def-easy-hint 2158240 "若い 時 の 苦労 は 買うてもせよ")
(def-easy-hint 2202070 "勝負 は 時 の 運")
(def-easy-hint 2227110 "カエサル の もの は カエサル に")
(def-easy-hint 2417800 "蛇 の 道 は 蛇")
(def-easy-hint 2418170 "親 の 光 は 七光り")
(def-easy-hint 2420070 "旅 の 恥 は 掻き捨て")
(def-easy-hint 2420100 "隣 の 花 は 赤い")
(def-easy-hint 2582990 "狐 の 子 は 頬白")
(def-easy-hint 2697510 "君父 の 讐 は 倶に 天 を 戴かず")
(def-easy-hint 2827732 "若い 時 の 苦労 は 買ってもせよ")
(def-easy-hint 2835925 "煩悩 の 犬 は 追えども 去らず")

;; は の
(def-easy-hint 1487700 "必要 は 発明 の 母")
(def-easy-hint 1320150 "失敗 は 成功 の もと")
(def-easy-hint 2126750 "悪妻 は 百年 の 不作")
(def-easy-hint 2141010 "逢う は 別れ の 始め")
(def-easy-hint 2144040 "商い は 牛 の よだれ")
(def-easy-hint 2152780 "苦 は 楽 の 種")
(def-easy-hint 2211780 "情け は 人 の 為 ならず")
(def-easy-hint 2416720 "嘘つき は 泥棒 の 始まり")
(def-easy-hint 2416970 "教うる は 学ぶ の 半ば")
(def-easy-hint 2417350 "口 は 禍 の 元")
(def-easy-hint 2417610 "子 は 三界 の 首枷")
(def-easy-hint 2417810 "弱き者 よ 汝 の 名 は 女 也")
(def-easy-hint 2418340 "人間 は 万物 の 霊長")
(def-easy-hint 2418470 "据え膳 食わぬ は 男 の 恥")
(def-easy-hint 2418540 "正直 は 一生 の 宝")
(def-easy-hint 2418590 "生兵法 は 大怪我 の もと")
(def-easy-hint 2419020 "朝起き は 三文 の 徳")
(def-easy-hint 2420140 "恋 は 思案 の 外")
(def-easy-hint 2550210 "幸運 の 女神 は 前髪 しかない")
(def-easy-hint 2591070 "火事 と 喧嘩 は 江戸 の 華")
(def-easy-hint 2716860 "そう は イカ の 金玉")
(def-easy-hint 2796370 "禍福 は 糾える 縄 の ごとし")
(def-easy-hint 2833968 "人間 は 万物 の 尺度 である")
(def-easy-hint 2833958 "言葉 は 身 の 文")
(def-easy-hint 2832652 "挨拶 は 時 の 氏神")
(def-easy-hint 2111130 "早起き は 三文 の 徳")
(def-easy-hint 2417830 "酒 は 百薬 の 長")

;; は を
(def-easy-hint 1213500 "甘言 は 偶人 を 喜ばす")
(def-easy-hint 1470130 "能 ある 鷹 は 爪 を 隠す")
(def-easy-hint 1929200 "悪貨 は 良貨 を 駆逐する")
(def-easy-hint 2077530 "類 は 友 を 呼ぶ")
(def-easy-hint 2079030 "大 は 小 を 兼ねる")
(def-easy-hint 2089460 "鳴く 猫 は 鼠 を 捕らぬ")
(def-easy-hint 2102600 "おぼれる 者 は わら をも つかむ")
(def-easy-hint 2168340 "天 は 自ら 助くる 者 を 助く")
(def-easy-hint 2416900 "急いて は 事 を 仕損ずる")
(def-easy-hint 2417110 "芸 は 身 を 助く")
(def-easy-hint 2419100 "天 は 二物 を 与えず")
(def-easy-hint 2419810 "名 は 体 を 表す")
(def-easy-hint 2520680 "義 を 見てせざる は 勇なきなり")
(def-easy-hint 2627320 "急いて は 事 を 仕損じる")
(def-easy-hint 2686140 "大人 は 赤子 の 心 を 失わず")
(def-easy-hint 2833952 "足る を 知る 者 は 富む")
(def-easy-hint 2832631 "井蛙 は 以って 海 を 語る 可からず")
(def-easy-hint 2832604 "良禽 は 木 を 択んで棲む")
(def-easy-hint 2757650 "日光 を 見ない 中 は 結構 と言う な")
(def-easy-hint 2419440 "敗軍 の 将 は 兵 を 語らず")
(def-easy-hint 2834645 "飢えたる 犬 は 棒 を 恐れず")
(def-easy-hint 2836094 "満 は 損 を 招く")

;; と は
(def-easy-hint 2095170 "天才 と 狂人 は 紙一重")
(def-easy-hint 2237240 "女房 と 畳 は 新しい 方がいい")
(def-easy-hint 2835775 "今 となって は")

;; は が
(def-easy-hint 2124980 "そう は 問屋 が 卸さない")
(def-easy-hint 2395080 "過ぎたる は 及ばざる が ごとし")
(def-easy-hint 2395090 "過ぎたる は 猶及ばざる が 如し")
(def-easy-hint 2417400 "慌てる 乞食 は もらい が 少ない")
(def-easy-hint 2419860 "明日 は 明日 の 風 が 吹く")

;; は に
(def-easy-hint 2138600 "百聞 は 一見 に しかず")
(def-easy-hint 2153120 "良薬 は 口 に 苦し")
(def-easy-hint 2153130 "目 は 口 ほど に 物を言う")
(def-easy-hint 2168390 "鉄 は 熱い うち に 打て")
(def-easy-hint 2171910 "去る者 は 日々 に 疎し")
(def-easy-hint 2416560 "ローマ は 一日 に して 成らず")
(def-easy-hint 2416730 "運 は 天 に 在り")
(def-easy-hint 2416800 "火 の ない ところ に 煙 は 立たない")
(def-easy-hint 2417160 "健全なる 精神 は 健全なる 身体 に 宿る")
(def-easy-hint 2417390 "孝行 の したい 時分 に 親 は なし")
(def-easy-hint 2418120 "新しい 酒 は 古い 革袋 に 入れる")
(def-easy-hint 2418130 "深い 川 は 静かに 流れる")
(def-easy-hint 2418450 "水 は 低きに 流る")
(def-easy-hint 2418750 "すべて の 道 は ローマ に 通ず")
(def-easy-hint 2419080 "鉄 は 熱い うち に 鍛え よ")
(def-easy-hint 2420150 "老いて は 子 に 従え")
(def-easy-hint 2566010 "秋茄子 は 嫁 に 食わす な")
(def-easy-hint 2832573 "巧詐 は 拙誠 に 如かず")
(def-easy-hint 2704850 "花泥棒 は 罪 に ならない")

;; に は

(def-easy-hint 2418150 "親 に 似ぬ 子 は 鬼子")
(def-easy-hint 2419940 "柳 の 下 に 何時も 泥鰌 は 居ない")
(def-easy-hint 2832738 "身体髪膚 これ を 父母 に 受くあえて 毀傷せざる は 孝 の 始めなり")
(def-easy-hint 2834655 "親 の 意見 と 茄子 の 花 は 千 に 一つ も 無駄 は ない")
(def-easy-hint 2830412 "他 に 方法 は 無い")
(def-easy-hint 2666530 "墓 に 布団 は 着せられぬ")

;; unsorted

(def-easy-hint 2834606 "親 は 無く とも 子 は 育つ")
(def-easy-hint 2834583 "病 は 口 より 入り 禍 は 口 より 出ず")
(def-easy-hint 2834582 "安物 は 高物")
(def-easy-hint 2834576 "目 は 心 の 鏡")
(def-easy-hint 2834575 "目 は 心 の 窓")
(def-easy-hint 2834651 "冷や酒 と 親 の 意見 は 後 で きく")
(def-easy-hint 2834564 "火 の 無い ところ に 煙 は 立たなぬ")
(def-easy-hint 2834563 "徳 は 孤 ならず 必ず 隣 あり")
(def-easy-hint 2834560 "君子 は 器 ならず")
(def-easy-hint 2834416 "馬鹿 は 風邪 を 引かない")
(def-easy-hint 2834363 "墨 は 餓鬼 に 磨らせ 筆 は 鬼 に 持たせよ")
(def-easy-hint 2834360 "信 は 荘厳 より 起こる")
(def-easy-hint 2834321 "父母 の 恩 は 山 よりも 高く 海 よりも 深し")
(def-easy-hint 2834318 "二人 は 伴侶 三人 は 仲間割れ")
(def-easy-hint 2834316 "人 の 花 は 赤い")
(def-easy-hint 2834313 "紅 は 園生 に 植えても 隠れなし")
(def-easy-hint 2834310 "地獄 は 壁一重")
(def-easy-hint 2834309 "人 は 死して 名 を 留む")
(def-easy-hint 2834308 "浮世 は 夢")
(def-easy-hint 2834287 "隣 の 芝 は 青い")
(def-easy-hint 2834263 "弱き者 汝 の 名 は 女 なり")
(def-easy-hint 2834244 "知識 は 力 なり")
(def-easy-hint 2834239 "武士 は 食わねど 高楊枝")
(def-easy-hint 2834233 "貧 は 世界 の 福 の 神")
(def-easy-hint 2834232 "光 は 東 から")
(def-easy-hint 2834228 "馬 に 乗る まで は 牛 に 乗れ")
(def-easy-hint 2834227 "言わぬ は 言う に 優る")
(def-easy-hint 2834224 "合わせ物 は 離れ物")
(def-easy-hint 2834220 "悪 は 延べよ")
(def-easy-hint 2833980 "牛 は 牛連れ 馬 は 馬連れ")
(def-easy-hint 2833979 "馬鹿 と 天才 は 紙一重")
(def-easy-hint 2833939 "長い物 には 巻かれ よ")
(def-easy-hint 2833938 "長い物 には 巻かれろ")

(def-easy-hint 2835463 "人目 も はばからず")
