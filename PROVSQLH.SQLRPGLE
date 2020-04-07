000100200407       //**************************************************************************
000101200407       //* THIS PROGRAM USES A CURSOR TO LOAD A TEMPORARY RESULT TABLE FROM 3
000102200407       //* SEPARATE TABLES, ONTARIO, QUEBEC AND MANITOBA. A NUMBER IS PASSED
000103200407       //* TO THE PROGRAM TO DETERMINE WHICH RECORDS ARE INLCUDED FROM THE 3 TABLES
000104200407       //**************************************************************************
000105200407           DCL-F PROVREPORT PRINTER OFLIND(*IN01) ;
000106200407           DCL-S ProvinceH    Char(10);
000107200407           DCL-S EndOfFile    IND;
000108200407           DCL-S TotalRecords PACKED(5:0) ;
000109200407             // LowLimit is passed to the program
000110200407           DCL-PI Main ExtPgm('PROVSQLH');
000111200407             LowLimitIn Packed(15:5);
000112200407           END-PI;
000113200407
000114200407
000115200407             // All Host Variables available under a single name
000116200407            DCL-DS CustomerRecord;
000117200407              CustID Char(6);
000118200407              FullName Char(31);
000119200407              City Char(20);
000120200407              Purchase Packed(7:2);
000121200407              PDate Date;
000122200407              Province Char(10);
000123200407        End-Ds CustomerRecord;
000124200407     C/EJECT
000125200407     C**************************************************************************
000126200407     C*                        ***   M A I N   R O U T I N E   ***
000127200407     C**************************************************************************
000128200407      /FREE
000129200407                LowLimit = LowLimitIn;
000130200407                EXSR PrepareFiles;
000131200407                Write Title;
000132200407                Write HEADINGS;
000133200407                EXSR GetRow;
000134200407                Write NewProv;
000135200407                ProvinceH = Province;
000136200407                DOW NOT EndOfFile;
000137200407                    IF *IN01 = *ON;
000138200407                        Write Title;
000139200407                        Write HEADINGS;
000140200407                       *IN01 = *OFF;
000141200407                    ENDIF;
000142200407                    // Province may change
000143200407                 IF ProvinceH = Province;
000144200407                   Write Detail;
000145200407               ELSE;
000146200407                   ProvinceH = Province;
000147200407                   Write Totals;
000148200407                   TotalPurch = 0;
000149200407                   Write NewProv;
000150200407                   Write Detail;
000151200407               ENDIF;
000152200407                    TotalPurch     = TotalPurch     + Purchase;
000153200407                    TotalRecords= TotalRecords + 1;
000154200407                    EXSR GetRow;
000155200407                ENDDO;
000156200407                Write Totals;
000157200407                EXSR   WRAPUP;
000158200407                Write UnderLimit;
000159200407                *INLR = *ON;
000160200407                RETURN;
000161200407        //**********************************************************************
000162200407        // O P E N F I L E S   S U B R O U T I N E
000163200407        //**********************************************************************
000164200407         BEGSR  PrepareFiles;
000165200407        // S E T   U P   T H E   T E M P O R A R Y   R E S U L T  STRUCTURE
000166200407       EXEC SQL
000167200407         DECLARE ALLPROVCURSOR CURSOR
000168200407         FOR
000169200407         SELECT CUSTID, TRIM(FNAME) || ' ' || TRIM(LNAME),
000170200407           CITY, PURCHASE, PDATE,
000171200407           'Ontario' AS PROVINCE
000172200407           FROM BCI433LIB/ONTARIO
000173200407           WHERE PURCHASE > :LowLimit
000174200407           UNION ALL
000175200407         SELECT CUSTID, TRIM(FNAME) || ' ' || TRIM(LNAME),
000176200407           CITY, PURCHASE, PDATE,
000177200407           'Quebec' AS PROVINCE
000178200407         FROM BCI433LIB/QUEBEC
000179200407         WHERE PURCHASE > :LowLimit
000180200407         UNION ALL
000181200407         SELECT CUSTID, TRIM(FNAME) || ' ' || TRIM(LNAME),
000182200407           CITY, PURCHASE, PDATE,
000183200407           'Manitoba' AS PROVINCE
000184200407         FROM BCI433LIB/MANITOBA
000185200407         WHERE PURCHASE > :LowLimit
000186200407         FOR READ ONLY;
000187200407
000188200407        // A   T E M P O R A R Y   R E S U L T   T A B L E   I S   C R E A T E D
000189200407        EXEC SQL
000190200407         OPEN ALLPROVCURSOR;
000191200407         If SQLCODE <> 0 OR SQLWN0 = 'W';
000192200407           EndOfFile = *ON;
000193200407         ENDIF;
000194200407            ENDSR;
000195200407        //**********************************************************************
000196200407        //   G E T     R O W    S U B R O U T I N E
000197200407        //**********************************************************************
000198200407            BEGSR     GETROW;
000199200407
000200200407            EXEC SQL
000201200407           FETCH NEXT
000202200407             FROM ALLPROVCURSOR
000203200407             INTO :CUSTOMERRECORD;
000204200407           If SQLCODE <> 0 OR SQLWN0 = 'W';
000205200407             EndOfFile = *ON;
000206200407           ENDIF;
000207200407             ENDSR;
000208200407        //**********************************************************************
000209200407        // W R A P U P     S U B R O U T I N E
000210200407        //**********************************************************************
000211200407           BEGSR WRAPUP;
000212200407             EXEC SQL
000213200407               CLOSE ALLPROVCURSOR;
000214200407               If SQLCODE <> 0 OR SQLWN0 = 'W';
000215200407                 EndOfFile = *ON;
000216200407               EndIf;
000217200407             EXEC SQL
000218200407               SELECT COUNT(*) INTO :ONTTOTAL
000219200407                 From BCI433LIB/ONTARIO
000220200407                 Where Purchase <=:LowLimit;
000221200407               If SQLCODE <> 0 OR SQLWN0 = 'W';
000222200407                 ONTTOTAL = -999;
000223200407               ENDIF;
000224200407             EXEC SQL
000225200407               SELECT COUNT(*) INTO :QUETOTAL
000226200407                 From BCI433LIB/QUEBEC
000227200407                 Where Purchase <=:LowLimit;
000228200407               If SQLCODE <> 0 OR SQLWN0 = 'W';
000229200407                 QUETOTAL  = -999;
000230200407               ENDIF;
000231200407             EXEC SQL
000232200407               SELECT COUNT(*) INTO :MANTOTAL
000233200407                 From BCI433LIB/MANITOBA
000234200407                 Where Purchase <=:LowLimit;
000235200407               If SQLCODE <> 0 OR SQLWN0 = 'W';
000236200407                 MANTOTAL = -999;
000237200407               ENDIF;
000238200407          ENDSR;
000239200407
