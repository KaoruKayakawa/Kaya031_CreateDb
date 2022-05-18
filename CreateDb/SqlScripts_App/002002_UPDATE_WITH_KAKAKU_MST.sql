USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UPDATE_WITH_KAKAKU_MST]') AND type in (N'P'))
DROP PROCEDURE [dbo].[UPDATE_WITH_KAKAKU_MST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: UPDATE_WITH_KAKAKU_MST
-- 機能			: BASE DB KAKAKU_MST_now の内容を、JYUCYU DB KAKAKU_M_now・KAKAKU_M に反映する。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/07/12  作成者 : 茅川
-- 更新			: 2021/10/19　茅川
--					: 2021/11/10　茅川
--					: 2021/12/08　茅川
--					: 2022/01/21　茅川
--					: 2022/01/24　茅川
--					: 2022/02/25　茅川
--					: 2022/05/09　茅川
-- ====================================================
CREATE PROCEDURE [dbo].[UPDATE_WITH_KAKAKU_MST]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_UPDATE_WITH_KAKAKU_MST;
		ELSE 
			BEGIN TRANSACTION;
	END TRY
	BEGIN CATCH
		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
	END CATCH

	BEGIN TRY
		DECLARE @valInt int;
		SELECT @valInt = CAST(ASTM_SETVALUE AS int) FROM APP_SETTING_M WHERE ASTM_SETKBN = 'CalendarTekiyoCount' AND ASTM_SETDTLKBN ='X';

		IF @valInt IS NULL
		BEGIN
			SET @ErrMessage = N'テーブル [APP_SETTING_M] に "CalendarTekiyoCount" の設定が見つかりません。';
			SET @ErrSeverity = 11;
			SET @ErrState = 1;

			RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
		END
		
		DECLARE @nowDt datetime = GETDATE();
		DECLARE @nowYmd datetime = CAST(@nowDt AS date);
		DECLARE @tekiYmd datetime = DATEADD(day, @valInt, @nowYmd);
		DECLARE @delYmd datetime = DATEADD(day, -10, @nowYmd);

		DECLARE @db_opeEnv varchar(256);
		SELECT @db_opeEnv = ASTM_SETVALUE FROM APP_SETTING_M WHERE ASTM_SETKBN = 'DatabaseOperatingEnvironment' AND ASTM_SETDTLKBN ='X';

		IF @db_opeEnv IS NULL
		BEGIN
			SET @ErrMessage = N'テーブル [APP_SETTING_M] に "DatabaseOperatingEnvironment" の設定が見つかりません。';
			SET @ErrSeverity = 11;
			SET @ErrState = 1;

			RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
		END

		DECLARE @propName_base sysname = N'UPDATE_WITH_KAKAKU_MST__LastExecution_DateTime';
		IF @db_opeEnv = 'verify'
			SET @propName_base = @propName_base + N'__VERIFY';
		DECLARE @lastExeDt1 datetime, @lastExeDt2 datetime;

		SELECT @lastExeDt1 = CAST(value AS datetime)
		FROM BASE_TBL_EXPROP
		WHERE [tbl_name] = N'KAKAKU_MST_now'
			AND [name] = @propName_base;

		IF @lastExeDt1 IS NULL
		BEGIN
			SET @lastExeDt2 = @nowDt;

			EXEC #{-BASE_DB-}#.sys.sp_addextendedproperty @name = @propName_base,
				@value = @lastExeDt2,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'KAKAKU_MST_now';

			SET @lastExeDt1 = '2000-12-31 23:59:59';
		END;
		ELSE
		BEGIN
			-- システム日時がメンテナンスされている場合を考慮
			IF @nowDt > @lastExeDt1
				SET @lastExeDt2 = @nowDt;
			ELSE
				SET @lastExeDt2= DATEADD(second, 1, @lastExeDt1);
				
			EXEC #{-BASE_DB-}#.sys.sp_updateextendedproperty @name = @propName_base,
				@value = @lastExeDt2 ,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'KAKAKU_MST_now';
		END;

		SELECT *, dbo.CONVERT_HTCD(SKAK_KCD, SKAK_HTCD) AS TENCD
		INTO #wt_UPDATE_WITH_KAKAKU_MST_101
		FROM KAKAKU_MST_now
		WHERE SKAK_KOSINYMD > @lastExeDt1;
		
		-- 新規レコードの [適用日] 以外のプライマリキーが一致するレコードを、更新対象に含める。
		-- ※ 本プロシージャでの削除処理を、正しく行うために必要。
		SELECT DISTINCT SKAK_KCD, SKAK_HTCD, SKAK_SCD, SKAK_KIKAKUCD
		INTO #wt_UPDATE_WITH_KAKAKU_MST_101_1
		FROM #wt_UPDATE_WITH_KAKAKU_MST_101;

		WITH
			t1 AS (
				SELECT a.*
				FROM KAKAKU_MST_now a
				INNER JOIN #wt_UPDATE_WITH_KAKAKU_MST_101_1 b
				ON a.SKAK_KCD = b.SKAK_KCD
					AND a.SKAK_HTCD = b.SKAK_HTCD
					AND a.SKAK_SCD = b.SKAK_SCD
					AND a.SKAK_KIKAKUCD = b.SKAK_KIKAKUCD
				LEFT OUTER JOIN #wt_UPDATE_WITH_KAKAKU_MST_101 c
				ON a.SKAK_KCD = c.SKAK_KCD
					AND a.SKAK_HTCD = c.SKAK_HTCD
					AND a.SKAK_SCD = c.SKAK_SCD
					AND a.SKAK_KIKAKUCD = c.SKAK_KIKAKUCD
					AND a.SKAK_TEKIYOYMD = c.SKAK_TEKIYOYMD
				WHERE c.SKAK_KCD IS NULL
			)
		INSERT INTO #wt_UPDATE_WITH_KAKAKU_MST_101
		SELECT *, dbo.CONVERT_HTCD(SKAK_KCD, SKAK_HTCD) AS TENCD
		FROM t1;

		DROP TABLE #wt_UPDATE_WITH_KAKAKU_MST_101_1;

		-- 保留レコードを登録対象に含める ->
		WITH
			t2 AS (
				SELECT *
				FROM UPDATE_PENDING
				WHERE UDP_TBL = N'KAKAKU_MST'
			)
		INSERT INTO #wt_UPDATE_WITH_KAKAKU_MST_101
		SELECT t1.*,  t2.UDP_TENCD
		FROM KAKAKU_MST_now t1
		INNER JOIN t2
		ON t1.SKAK_KCD = t2.UDP_KCD
			AND t1.SKAK_HTCD = t2.UDP_HTCD
			AND t1.SKAK_TEKIYOYMD = t2.UDP_TEKIYOYMD
			AND t1.SKAK_UPDATECNT = t2.UDP_UPDATECNT			-- 更新されたレコードは除く
			AND t1.SKAK_SCD = CAST(t2.UDP_KEY1 AS bigint)
			AND t1.SKAK_KIKAKUCD = CAST(t2.UDP_KEY2 AS bigint)
		LEFT OUTER JOIN #wt_UPDATE_WITH_KAKAKU_MST_101 t3		-- 重複する場合もあるので考慮にいれる
		ON t1.SKAK_KCD = t3.SKAK_KCD
			AND t1.SKAK_HTCD = t3.SKAK_HTCD
			AND t1.SKAK_TEKIYOYMD = t3.SKAK_TEKIYOYMD
			AND t1.SKAK_SCD = t3.SKAK_SCD
			AND t1.SKAK_KIKAKUCD = t3.SKAK_KIKAKUCD
		WHERE t3.SKAK_KCD IS NULL;
			
		DELETE FROM UPDATE_PENDING
		WHERE UDP_TBL = N'KAKAKU_MST';
		-- <- 保留レコードを登録対象に含める

		DELETE a
		FROM KAKAKU_M_now a
		INNER JOIN #wt_UPDATE_WITH_KAKAKU_MST_101 b
		ON a.KAK_HTCD = b.TENCD
			AND a.KAK_SCD = b.SKAK_SCD
			AND a.KAK_KIKAKUCD = b.SKAK_KIKAKUCD
			AND a.KAK_TEKIYOYMD = b.SKAK_TEKIYOYMD;

		SELECT t1.*, t2.SSHM_FUTEIKANKBN, t2.SSHM_MAXGRAM
		INTO #wt_UPDATE_WITH_KAKAKU_MST_102
		FROM #wt_UPDATE_WITH_KAKAKU_MST_101 t1
		LEFT OUTER JOIN vi_SHOHIN_MST t2
		ON t1.TENCD = dbo.CONVERT_HTCD(t2.SSHM_KCD, t2.SSHM_HTCD)
			AND t1.SKAK_SCD = t2.SSHM_SCD
			AND (t1.SKAK_TEKIYOYMD BETWEEN t2.SSHM_TEKIYOYMD AND t2.SSHM_TEKIYOYMD_END);

		/* エラーとしないが、KAKAKU_M_now には登録されない。
		SELECT @valInt = COUNT(*) FROM #wt_UPDATE_WITH_KAKAKU_MST_102 WHERE SKAK_DELFG = 0 AND SSHM_FUTEIKANKBN IS NULL;
		
		IF @valInt > 0
		BEGIN
			SET @ErrMessage = N'商品マスタ [SHOHIN_MST] に未登録の商品コードが、テーブル [KAKAKU_MST_now] に含まれています。';
			SET @ErrSeverity = 11;
			SET @ErrState = 1;
  
			RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
		END
		*/

		-- 保留レコード登録
		INSERT INTO UPDATE_PENDING (
			UDP_TBL,
			UDP_KCD,
			UDP_HTCD,
			UDP_TEKIYOYMD,
			UDP_UPDATECNT,
			UDP_KEY1,
			UDP_KEY2,
			UDP_NOTE,
			UDP_TENCD
		)
		SELECT N'KAKAKU_MST',
			SKAK_KCD,
			SKAK_HTCD,
			SKAK_TEKIYOYMD,
			SKAK_UPDATECNT,
			SKAK_SCD,
			SKAK_KIKAKUCD,
			N'[商品] 未登録（SHOHIN_MST_now）',
			TENCD
		FROM #wt_UPDATE_WITH_KAKAKU_MST_102
		WHERE SKAK_DELFG = 0
			AND SSHM_FUTEIKANKBN IS NULL;

		INSERT INTO KAKAKU_M_now
		SELECT
			TENCD,
			SKAK_SCD,
			SKAK_KIKAKUCD,
			SKAK_TEKIYOYMD,
			SKAK_UPDATECNT,
			SKAK_TOKUSTR,
			SKAK_TOKUEND,
			ISNULL(SKAK_TOKUKBN, 0),
			SKAK_TOKUGENKA,
			ISNULL(SKAK_TOKUTANKA, 0),
			dbo.CONVERT_SURYOSEIGEN(SKAK_SURYOSEIGEN, SKAK_SEIGYOKBN, SKAK_TEISHIKBN),
			ISNULL(SKAK_TOKUKEISAIJUN, 0),
			ISNULL(SKAK_TOKUSJKBN, 0),
			SKAK_100BAIKA,
			SKAK_KEISAI_OVERRIDE,
			SKAK_DELFG,
			SKAK_INYMD,
			SKAK_INTANTO,
			SKAK_KOSINYMD,
			SKAK_KOSINTANTO
		FROM #wt_UPDATE_WITH_KAKAKU_MST_102
		WHERE SSHM_FUTEIKANKBN IS NULL AND SKAK_DELFG = 2;

		INSERT INTO KAKAKU_M_now
		SELECT
			TENCD,
			SKAK_SCD,
			SKAK_KIKAKUCD,
			SKAK_TEKIYOYMD,
			SKAK_UPDATECNT,
			SKAK_TOKUSTR,
			SKAK_TOKUEND,
			ISNULL(SKAK_TOKUKBN, 0),
			SKAK_TOKUGENKA,
			ISNULL(SKAK_TOKUTANKA, 0),
			dbo.CONVERT_SURYOSEIGEN(SKAK_SURYOSEIGEN, SKAK_SEIGYOKBN, SKAK_TEISHIKBN),
			ISNULL(SKAK_TOKUKEISAIJUN, 0),
			ISNULL(SKAK_TOKUSJKBN, 0),
			SKAK_100BAIKA,
			SKAK_KEISAI_OVERRIDE,
			SKAK_DELFG,
			SKAK_INYMD,
			SKAK_INTANTO,
			SKAK_KOSINYMD,
			SKAK_KOSINTANTO
		FROM #wt_UPDATE_WITH_KAKAKU_MST_102
		WHERE SSHM_FUTEIKANKBN <> 1 AND SKAK_DELFG <> 1;
		
		SELECT
			TENCD,
			SKAK_SCD,
			SKAK_KIKAKUCD,
			SKAK_TEKIYOYMD,
			SKAK_UPDATECNT,
			SKAK_TOKUSTR,
			SKAK_TOKUEND,
			ISNULL(SKAK_TOKUKBN, 0) AS TOKUKBN,
			SKAK_TOKUGENKA,
			ISNULL(CEILING(SKAK_100BAIKA * SSHM_MAXGRAM * 0.01), 0) AS TOKUTANKA,
			dbo.CONVERT_SURYOSEIGEN(SKAK_SURYOSEIGEN, SKAK_SEIGYOKBN, SKAK_TEISHIKBN) AS TSURYOSEIGEN,
			ISNULL(SKAK_TOKUKEISAIJUN, 0) AS TOKUKEISAIJUN,
			ISNULL(SKAK_TOKUSJKBN, 0) AS TOKUSJKBN,
			SKAK_100BAIKA,
			SKAK_KEISAI_OVERRIDE,
			SKAK_DELFG,
			SKAK_INYMD,
			SKAK_INTANTO,
			SKAK_KOSINYMD,
			SKAK_KOSINTANTO
		INTO #wt_UPDATE_WITH_KAKAKU_MST_103
		FROM #wt_UPDATE_WITH_KAKAKU_MST_102
		WHERE SSHM_FUTEIKANKBN = 1 AND SKAK_DELFG <> 1;

		DROP TABLE #wt_UPDATE_WITH_KAKAKU_MST_102;

		UPDATE #wt_UPDATE_WITH_KAKAKU_MST_103
		SET TOKUTANKA = 2
		WHERE TOKUTANKA < 2;

		INSERT INTO KAKAKU_M_now
		SELECT
			TENCD,
			SKAK_SCD,
			SKAK_KIKAKUCD,
			SKAK_TEKIYOYMD,
			SKAK_UPDATECNT,
			SKAK_TOKUSTR,
			SKAK_TOKUEND,
			TOKUKBN,
			SKAK_TOKUGENKA,
			TOKUTANKA,
			TSURYOSEIGEN,
			TOKUKEISAIJUN,
			TOKUSJKBN,
			SKAK_100BAIKA,
			SKAK_KEISAI_OVERRIDE,
			SKAK_DELFG,
			SKAK_INYMD,
			SKAK_INTANTO,
			SKAK_KOSINYMD,
			SKAK_KOSINTANTO
		FROM #wt_UPDATE_WITH_KAKAKU_MST_103;

		DROP TABLE #wt_UPDATE_WITH_KAKAKU_MST_103;

		-- 不要レコード削除（適用日）
		DELETE a
		FROM KAKAKU_M_now a
		LEFT OUTER JOIN ft_KAKAKU_M(@delYmd) b
		ON a.KAK_HTCD = b.KAK_HTCD
			AND a.KAK_SCD = b.KAK_SCD
			AND a.KAK_KIKAKUCD = b.KAK_KIKAKUCD
		WHERE a.KAK_TEKIYOYMD < b.KAK_TEKIYOYMD
			OR (b.KAK_TEKIYOYMD IS NULL AND a.KAK_TEKIYOYMD <= @delYmd);

		-- 不要レコード削除（配達終了日）	※ プライマリーキー単位での削除
		WITH
			t2 AS (
				SELECT KAK_HTCD, KAK_SCD, KAK_KIKAKUCD
				FROM KAKAKU_M_now
				GROUP BY KAK_HTCD, KAK_SCD, KAK_KIKAKUCD
				HAVING MAX(KAK_TOKUEND) < @delYmd
			)
		DELETE t1
		FROM KAKAKU_M_now t1
		INNER JOIN t2
		ON t1.KAK_HTCD = t2.KAK_HTCD
			AND t1.KAK_SCD = t2.KAK_SCD
			AND t1.KAK_KIKAKUCD = t2.KAK_KIKAKUCD;
			
		-- テーブル KAKAKU_M の更新（日替わりの一回目は TRUNCATE を行い、全レコードを再作成する） ->
		DECLARE @propName_app sysname = N'UPDATE_WITH_KAKAKU_MST__Truncate_DateTime';
		DECLARE @truncDt datetime;

		SELECT @truncDt = CAST(value AS datetime)
		FROM sys.extended_properties
		WHERE class= 1
			AND major_id = OBJECT_ID(N'[dbo].[KAKAKU_M]')
			AND name = @propName_app;

		IF @truncDt IS NULL
		BEGIN
			SET @truncDt = DATEADD(day, -1, @nowDt);

			EXEC sys.sp_addextendedproperty @name = @propName_app,
				@value = @truncDt,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'KAKAKU_M';
		END;

		IF CAST(@truncDt AS date) < @nowYmd
		BEGIN
			TRUNCATE TABLE KAKAKU_M;

			INSERT INTO KAKAKU_M
			SELECT
				KAK_HTCD,
				KAK_SCD,
				KAK_KIKAKUCD,
				KAK_TOKUKBN,
				KAK_TOKUSTR,
				KAK_TOKUEND,
				KAK_TOKUGENKA,
				KAK_TOKUTANKA,
				KAK_TSURYOSEIGEN,
				KAK_TOKUKEISAIJUN,
				KAK_TOKUSJKBN,
				KAK_INYMD,
				KAK_KOSINYMD,
				KAK_KOSINYMD,
				KAK_100BAIKA,
				KAK_KEISAI_OVERRIDE
			FROM ft_KAKAKU_M(@tekiYmd);

			EXEC sys.sp_updateextendedproperty @name = @propName_app,
				@value = @nowDt,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'KAKAKU_M';
		END;
		ELSE
		BEGIN
			SELECT DISTINCT
				TENCD,
				SKAK_SCD,
				SKAK_KIKAKUCD
			INTO #wt_UPDATE_WITH_KAKAKU_MST_104
			FROM #wt_UPDATE_WITH_KAKAKU_MST_101;

			DELETE a
			FROM KAKAKU_M a
			INNER JOIN #wt_UPDATE_WITH_KAKAKU_MST_104 b
			ON a.KAK_HTCD = b.TENCD
				AND a.KAK_SCD = b.SKAK_SCD
				AND a.KAK_KIKAKUCD = b.SKAK_KIKAKUCD;
				
			INSERT INTO KAKAKU_M
			SELECT
				a.KAK_HTCD,
				a.KAK_SCD,
				a.KAK_KIKAKUCD,
				a.KAK_TOKUKBN,
				a.KAK_TOKUSTR,
				a.KAK_TOKUEND,
				a.KAK_TOKUGENKA,
				a.KAK_TOKUTANKA,
				a.KAK_TSURYOSEIGEN,
				a.KAK_TOKUKEISAIJUN,
				a.KAK_TOKUSJKBN,
				a.KAK_INYMD,
				a.KAK_KOSINYMD,
				a.KAK_KOSINYMD,
				a.KAK_100BAIKA,
				a.KAK_KEISAI_OVERRIDE
			FROM ft_KAKAKU_M(@tekiYmd) a
			INNER JOIN #wt_UPDATE_WITH_KAKAKU_MST_104 b
			ON a.KAK_HTCD = b.TENCD
				AND a.KAK_SCD = b.SKAK_SCD
				AND a.KAK_KIKAKUCD = b.SKAK_KIKAKUCD;

			DROP TABLE #wt_UPDATE_WITH_KAKAKU_MST_104;
		END;
		-- <- テーブル KAKAKU_M の更新（日替わりの一回目は、TRUNCATE を行い、全レコードを再作成する）

		DROP TABLE #wt_UPDATE_WITH_KAKAKU_MST_101;
		
		-- 不要レコード削除（配達終了日）	※ プライマリーキー単位削除が行われなかったレコード
		DELETE FROM KAKAKU_M
		WHERE KAK_TOKUEND < @delYmd;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0
			ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_UPDATE_WITH_KAKAKU_MST;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
	END CATCH
END
GO
