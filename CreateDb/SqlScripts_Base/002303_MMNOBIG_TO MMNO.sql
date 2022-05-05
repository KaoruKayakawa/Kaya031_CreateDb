USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MMNOBIG_TO MMNO]') AND type in (N'P'))
DROP PROCEDURE [dbo].[MMNOBIG_TO MMNO]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- 名称			: MMNOBIG_TO MMNO
-- 機能			: CSV MMNO に割り当てられた、ＤＢ MMNO を取得する。
--				　※ 未割当なら、割当を行う。
-- 引き数		:
--   @mmnobig：CSV MMNO
--   @endymd：ミックスマッチ終了日
--   @mmno：ＤＢ MMNO
-- 戻り値		:
--   0：成功
--   1：MMNO 不足で割当不可
-- 作成			: 2021-05-12　茅川
-- ================================================
CREATE PROCEDURE [dbo].[MMNOBIG_TO MMNO]
	@mmnobig bigint, @endymd datetime,
	@mmno int OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT @mmno = MMNO
	FROM MIXMATCH_MMNO
	WHERE CSVMMNO = @mmnobig;

	IF @mmno IS NOT NULL
	BEGIN
		UPDATE MIXMATCH_MMNO
		SET ENDYMD = @endymd
		WHERE CSVMMNO = @mmnobig
			AND ENDYMD < @endymd;

		RETURN(0);
	END;

	WITH
		t1 AS (
			SELECT *,
				ROW_NUMBER() OVER(ORDER BY ENDYMD ASC) AS row_num
			FROM MIXMATCH_MMNO
			WHERE ENDYMD IS NULL OR ENDYMD < DATEADD(day, -7, CAST(GETDATE() AS date))
		)
	SELECT @mmno = MMNO
	FROM t1
	WHERE row_num = 1;

	IF @mmno IS NULL
		RETURN(1);

	UPDATE MIXMATCH_MMNO
	SET CSVMMNO = @mmnobig,
		ENDYMD = @endymd
	WHERE MMNO = @mmno;

	RETURN(0);
END

GO
