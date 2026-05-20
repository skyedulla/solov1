-- CreateTable
CREATE TABLE "decision_maps" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "idea_id" TEXT NOT NULL,
    "title" TEXT NOT NULL DEFAULT '',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "decision_maps_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "decision_maps_user_id_idx" ON "decision_maps"("user_id");

-- CreateIndex
CREATE INDEX "decision_maps_user_id_idea_id_idx" ON "decision_maps"("user_id", "idea_id");
