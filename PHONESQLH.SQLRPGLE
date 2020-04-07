000001200331         // **************************************************************************
000002200331        //  CUSTOMER20 READ BY NATIVE LANGUAGE (ILE RPG)
000003200331        //  CONTACTW20 ROW RETRIEVED WITH EMBEDDED SQL
000004200331        //  DETAIL REPORT LINE INCLUDES INFORMATION FROM CUSTOMER20 AND CONTACTW20
000005200331        //  SUMMARRY REPORT INFORMATION RETRIEVED WITH EMBEDDED SQL STATEMENTS
000006200331
000007200331           DCL-F PHNREPORT PRINTER OFLIND(*IN01) ;
000008200331           DCL-F CUSTOMER20 DISK(*EXT) KEYED USAGE(*INPUT)
000009200331                 RENAME(CUSTOMER20:CUSTR);
000010200331                      // data structure for host variables from CONTACTW20
000011200331           DCL-DS CONTACTW20 EXT END-DS;
000012200331                     // Standalone fields for indicator variables
000013200331           DCL-S INDLastCDate BINDEC(4:0);
000014200331           DCL-S INDNextCDate BINDEC(4:0);
000015200331
000016200331           DCL-S Dummy  Zoned(1);
000017200331
000018200331        //**************************************************************************
000019200331        //*                        ***   M A I N   R O U T I N E   ***
000020200331        //**************************************************************************
000021200331
000022200331                EXSR SummaryInfo;
000023200331                WRITE HEADINGS;
000024200331                READ CUSTOMER20;
000025200331                DOW NOT %EOF;
000027200331                    EXSR SQLSelect;
000028200331                     IF PHNLDC = OldestDate;
000029200331                      Flag = '<------';
000030200331                      ELSE;
000031200331                        Flag = '';
000032200331                     ENDIF;
000033200331                    IF *IN01 = *ON;
000034200331                       Write HEADINGS;
000035200331                       *IN01 = *OFF;
000036200331                    ENDIF;
000037200331                    Write DETAIL;
000038200331                   READ CUSTOMER20;
000039200331                ENDDO;
000040200331                Write SUMMARY;
000041200331                *INLR = *ON;
000042200331                RETURN;
000043200331        //**********************************************************************
000044200331        //   S Q L S E L E C T   S U B R O U T I N E
000045200331   //   //********************************************************************
000046200331   //                  BEGSR    SQLSelect ;
000047200331   //    // A row from the contacts table that has the same customer number as t
000048200331   //    // read from the CUSTOMER20 file is retrieved to find out the last date
000049200331   //    // phone number, comments and the salesperson number.
000050200331   //
000051200331   //    //  The call back interval is added to the last date called to determin
000052200331   //    //  next date to call.  Since null values may be stored in the last dat
000053200331   //    // indicator variables are used.
000054200331                   EXEC SQL
000055200331                   SELECT PHNLDC + PHNCIT DAYS, PHNLDC,
000056200331                     CSTPHN, PHNCOM, CSTSLN
000057200331                     INTO :NEXTCDATE :INDNextCDate, :PHNLDC :INDLastCDate,
000058200331                     :CSTPHN, :PHNCOM, :CSTSLN
000059200331                     FROM BCI433LIB/CONTACTW20
000060200331                     WHERE CSTNUM = :CSTNUM;
000061200331
000062200331                     SELECT;
000063200331                       WHEN SQLSTATE = '00000';
000064200331                         Dummy = 0;
000065200331                         WHEN SQLSTATE = '02000';
000066200331                           CSTPHN = 'Not Found';
000067200331                           NEXTCDATE = D'9999-09-09';
000068200331                           PHNLDC = D'9999-09-09';
000069200331                          PHNCOM = '***';
000070200331                          CSTSLN = '***';
000071200331                         WHEN %SUBST(SQLSTATE:1:2) = '01';
000072200331                          NEXTCDATE = D'9999-09-09';
000073200331                           PHNLDC = D'9999-09-09';
000074200331                          PHNCOM = '***';
000075200331                          CSTSLN = '***';
000076200331                          CSTPHN = '***';
000077200331                         OTHER;
000078200331                           CSTPHN = 'ALL*';
000079200331                           NEXTCDATE = D'9999-09-09';
000080200331                           PHNLDC = D'9999-09-09';
000081200331                           PHNCOM = 'ALL*';
000082200331                           CSTSLN = 'ALL*';
000083200331                     ENDSL;
000084200331
000085200331                           IF INDLastCDate = -1;
000086200331                            CSTPHN = 'UNKNOWN DATE';
000087200331                            NEXTCDATE = D'9999-09-09';
000088200331                            PHNLDC = D'9999-09-09';
000089200331                            ELSEIF INDLastCDate <> 0;
000090200331                            CSTPHN = 'DATE PROBLEM';
000091200331                            NEXTCDATE = D'9999-09-09';
000092200331                            PHNLDC = D'9999-09-09';
000093200331                            ENDIF;
000094200331
000095200331                         ENDSR ;
000096200331        //**********************************************************************
000097200331        // S U M M A R Y I N F O   S U B R O U T I N E
000098200331        //**********************************************************************
000099200331                         BEGSR  SummaryInfo;
000100200331        //  D E T E R M I N E   T O T A L S   F O R   CONTACTW20 & CUSTOMER20
000101200331                            EXEC SQL
000102200331                              SELECT COUNT(*) INTO :CONTACTT
000103200331                              FROM BCI433LIB/CONTACTW20;
000104200331
000105200331                              IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
000106200331                                CONTACTT = -99999;
000107200331                                ENDIF;
000108200331
000109200331                             EXEC SQL
000110200331                                 SELECT COUNT(*) INTO :CUSTOMERT
000111200331                                  FROM BCI433LIB/CUSTOMER20;
000112200331
000113200331                                IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
000114200331                                    CUSTOMERT = -99999;
000115200331                                   ENDIF;
000116200331
000117200331        // D E T E R M I N E   N U M B E R   O F   U N K N O W N   LAST   DATE CALLED
000118200331                              EXEC SQL
000119200331                                SELECT COUNT(*) INTO :UNKNOWNT
000120200331                                  FROM BCI433LIB/CONTACTW20
000121200331                                  WHERE PHNLDC IS NULL;
000122200331
000123200331                                 IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
000124200331                                   UNKNOWNT = -99999;
000125200331                                      ENDIF;
000126200331
000127200331
000128200331        //  D E T E R M I N E   O L D E S T   &  M O S T   R E C E N T  L A S T
000129200331                               EXEC SQL
000130200331                                 SELECT MIN(PHNLDC) INTO :OldestDate
000131200331                                   FROM BCI433LIB/CONTACTW20;
000132200331
000133200331                       IF (SQLCODE <> 0) OR (SQLWN0 = 'W') AND (SQLWN2 <> 'W');
000134200331                         OldestDate = D'9999-09-09';
000135200331                                  ENDIF;
000136200331
000137200331                                 EXEC SQL
000138200331                                 SELECT MAX(PHNLDC) INTO :RecentDate
000139200331                                  FROM BCI433LIB/CONTACTW20;
000140200331
000141200331                      IF (SQLCODE <> 0) OR (SQLWN0 = 'W') AND (SQLWN2 <> 'W');
000142200331                        RecentDate = D'9999-09-09';
000143200331                                 ENDIF;
000144200331
000145200331
000146200331       // D E T E R M I N E   T H E   U S E R   S E R V E R   &   T I M E S T A
000147200331                                     EXEC SQL
000148200331                 SELECT USER, CURRENT TIMESTAMP, CURRENT SERVER
000149200331                   INTO :User, :TimeStamp, :Server
000150200331                   FROM SYSIBM/SYSDUMMY1;
000151200331
000152200331                         ENDSR;
000153200331
