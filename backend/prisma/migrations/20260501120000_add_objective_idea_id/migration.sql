-- AlterTable
ALTER TABLE "objectives" ADD COLUMN "idea_id" TEXT;

-- Backfill: attach each objective to the user's oldest idea (same user only). Objectives whose user has no ideas are removed.
UPDATE "objectives" o
SET "idea_id" = sub."id"
FROM (
  SELECT DISTINCT ON (i."user_id") i."user_id", i."id"
  FROM "ideas" i
  ORDER BY i."user_id", i."created_at" ASC
) AS sub
WHERE o."user_id" = sub."user_id"
  AND o."idea_id" IS NULL;

DELETE FROM "objectives" WHERE "idea_id" IS NULL;

ALTER TABLE "objectives" ALTER COLUMN "idea_id" SET NOT NULL;

-- CreateIndex
CREATE INDEX "objectives_user_id_idea_id_idx" ON "objectives"("user_id", "idea_id");
