000100190313         // **************************************************************************
000200200326        //  CUSTOMER20 READ BY NATIVE LANGUAGE (ILE RPG)
000300200326        //  CONTACTW20 ROW RETRIEVED WITH EMBEDDED SQL
000400200326        //  DETAIL REPORT LINE INCLUDES INFORMATION FROM CUSTOMER20 AND CONTACTW20
000500190313        //  SUMMARRY REPORT INFORMATION RETRIEVED WITH EMBEDDED SQL STATEMENTS
000600190314
000700190313           DCL-F PHNREPORT PRINTER OFLIND(*IN01) ;
000800200326           DCL-F CUSTOMER20 DISK(*EXT) KEYED USAGE(*INPUT)
000900200326                 RENAME(CUSTOMER20:CUSTR);
001000200326                      // data structure for host variables from CONTACTW20
001100200331           DCL-DS CONTACTW20 EXT END-DS;
001200190314                     // Standalone fields for indicator variables
001300200331           DCL-S INDLastCDate BINDEC(4:0);
001301200331           DCL-S INDNextCDate BINDEC(4:0);
001400190314
001500190314
001600190314           DCL-S Dummy  Zoned(1);
001700190314
001800190314        //**************************************************************************
001900190314        //*                        ***   M A I N   R O U T I N E   ***
002000190314        //**************************************************************************
002100190314
002200070119                EXSR SummaryInfo;
002300190313                WRITE HEADINGS;
002400200326                READ CUSTOMER20;
002500070119                DOW NOT %EOF;
002600070119                    EXSR SQLSelect;
002700190313                    IF *IN01 = *ON;
002800190313                       Write HEADINGS;
002900190313                       *IN01 = *OFF;
003000070119                    ENDIF;
003100190313                    Write DETAIL;
003200200326                   READ CUSTOMER20;
003300070119                ENDDO;
003400190313                Write SUMMARY;
003500070119                *INLR = *ON;
003600070119                RETURN;
003700080923        //**********************************************************************
003800080923        //   S Q L S E L E C T   S U B R O U T I N E
003900080923   //   //********************************************************************
004000080923   //                  BEGSR    SQLSelect ;
004100080923   //    // A row from the contacts table that has the same customer number as t
004200200326   //    // read from the CUSTOMER20 file is retrieved to find out the last date
004300080923   //    // phone number, comments and the salesperson number.
004400080923   //
004500080923   //    //  The call back interval is added to the last date called to determin
004600080923   //    //  next date to call.  Since null values may be stored in the last dat
004700080923   //    // indicator variables are used.
004800190314
004900200331                EXEC SQL
004901200331                 SELECT PHNLDC + PHNCIT DAYS, PHNLDC,
004902200331                 CSTPHN, PHNCOM, CSTSLN
004903200331                 INTO: NEXTCDATE: INDNEXTCDATE, :PHNLDC :INDLASTCDATE,
004904200331                 FROM BCI433LIB/CONTACTW20
004905200331                 WHERE CSTNUM= :CSTNUM;
004906200331
004907200331                 SELECT;
004908200331                        WHEN SQLSTAT= '00000';
004909200331                          DUMMY=0;
004910200331                        WHEN SQLSTAT='02000';
004911200331                          CSTPHN = 'NOT FOUND';
004912200331                          NEXTCDATE= D'9999-09-09';
004913200331                          PHNLDC=  D'9999-09-09';
004914200331                          PHNCOM='***';
004915200331                          CSTSLN='***';
004916200331                         WHEN %SUBST(SQLSTATE:1:2)='01';
004917200331                          NEXTCDATE= D'9999-09-09';
004918200331                          PHNLDC=  D'9999-09-09';
004919200331                          PHNCOM='***';
004920200331                          CSTSLN='***';
004921200331                         OTHER;
004922200331                          CSTPHN='ALL*';
004923200331                          NEXTCDATE= D'9999-09-09';
004924200331                          PHNLDC=  D'9999-09-09';
004925200331                          PHNCOM='ALL*';
004926200331                          CSTSLN='ALL*';
004927200331                 ENDSL;
005000200331                   IF INDLASTCDATE= -1;
005001200331                       CSTPHN='UNKNOWN DATE';
005002200331                          NEXTCDATE= D'9999-09-09';
005003200331                          PHNLDC=  D'9999-09-09';
005004200331                   ELSEIF INDLASTCDATE<>0;
005005200331                     CSTPHN='DATE PROBLEM';
005006200331                          NEXTCDATE= D'9999-09-09';
005007200331                          PHNLDC=  D'9999-09-09';
005008200331                   ENDIF;
005100200331                  ENDSR;
005200200331
007000080923        //**********************************************************************
007100080923        // S U M M A R Y I N F O   S U B R O U T I N E
007200080923        //**********************************************************************
007300080923                         BEGSR  SummaryInfo;
007400200326        //  D E T E R M I N E   T O T A L S   F O R   CONTACTW20 & CUSTOMER20
007500200331               EXEC SQL
007501200331               SELECT COUNT(*) INTO :CONTACTT
007502200331               FROM BCI433LIB/CONTACTW20;
007503200331
007504200331                IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
007505200331                   CONTACTT = -99999;
007506200331                ENDIF;
007600190314
007700200331                EXEC SQL
007701200331                SELECT COUNT(*) INTO :CUSTOMERT
007702200331                FROM BCI433LIB/CUSTOMER20;
007703200331
007704200331                IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
007705200331                   CUSTOMERT = -99999;
007706200331                ENDIF;
007800190314
007900190314
008000190314
008100190314
008200190314
008300190314
008400190314
008500190314
008600190314
008700190314
008800190314
008900190314
009000190314        // D E T E R M I N E   N U M B E R   O F   U N K N O W N   LAST   DATE CALLED
009100200331               EXEC SQL
009200200331                SELECT COUNT(*) INTO :UNKNOWNT
009300200331                  FROM BCI433LIB/CONTACTW20
009400200331                  WHERE PHNLDC IS NULL;
009500190314
009600200331                  IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
009700200331                   UNKNOWNT = -99999;
009800200331                  ENDIF;
009900190314
010000190314
010100080923        //  D E T E R M I N E   O L D E S T   &  M O S T   R E C E N T  L A S T
010200200331                   EXEC SQL
010300200331                    SELECT MIN(PHNLDC) INTO :OldestDate
010400200331                     FROM BCI433LIB/CONTACTW20;
010500190314
010600200331                      IF (SQLCODE <> 0) OR (SQLWN0 = 'W') AND (SQLWN2 <> 'W');
010700200331                      OldestDate = D'9999-09-09';
010800200331                      ENDIF;
010900190314
011000200331                      EXEC SQL
011100200331                      SELECT MAX(PHNLDC) INTO :RecentDate
011200200331                      FROM BCI433LIB/CONTACTW20;
011300190314
011400200331                      IF (SQLCODE <> 0) OR (SQLWN0 = 'W') AND (SQLWN2 <> 'W');
011500200331                      RecentDate = D'9999-09-09';
011600200331                      ENDIF;
011700190314
011800190314
011900190314
012000190314
012100080923       // D E T E R M I N E   T H E   U S E R   S E R V E R   &   T I M E S T A
012200200331                     EXEC SQL
012300200331                     SELECT USER, CURRENT TIMESTAMP, CURRENT SERVER
012400200331                     INTO :USER, :TIMESTAMP, :SERVER
012500200331                     FROM SYSIBM/SYSDUMMY1;
012600200331
012800080923                         ENDSR;
