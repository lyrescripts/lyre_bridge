r"""
     _                       _____           _       _
    | |                     / ____|         (_)     | |      
    | |    _   _ _ __ ___  | (___   ___ _ __ _ _ __ | |_ ___ 
    | |   | | | | '__/ _ \  \___ \ / __| '__| | '_ \| __/ __|
    | |___| |_| | | |  __/  ____) | (__| |  | | |_) | |_\__ \
    |______\__, |_|  \___| |_____/ \___|_|  |_| .__/ \__|___/
            __/ |                             | |            
           |___/                              |_|

"""

"""Normalized job grades can be compared without mutating framework data."""

from lua_test_support import LuaTestCase


class JobGradeTests(LuaTestCase):
    def test_qb_and_qbx_grades_are_numeric_snapshots(self):
        for name in ("qbcore", "qbox"):
            with self.subTest(provider=name):
                self.setUp()
                provider = self.provider("server", "players", name)
                player = provider.getPlayerFromId(provider, 1)
                job = player.getJob()
                self.assertGreaterEqual(job.grade, 2)
                self.assertEqual((job.name, job.label, job.onduty), ("police", "Police", True))
                self.assertEqual(self.g.nativePlayers[1].PlayerData.job.grade.level, 3)
                job.grade = 99
                self.assertEqual(player.getJob().grade, 3)
                self.g.nativePlayers[1].PlayerData.job.grade = "4"
                self.assertEqual(player.getJob().grade, 4)

    def test_esx_numeric_grade_and_fields_are_preserved(self):
        provider = self.provider("server", "players", "esx")
        job = provider.getPlayerFromId(provider, 1).getJob()
        self.assertEqual((job.grade, job.grade_label), (3, "Sergeant"))

    def test_missing_job_is_nil_and_missing_grade_defaults_to_zero(self):
        provider = self.provider("server", "players", "qbox")
        player = provider.getPlayerFromId(provider, 1)
        self.g.nativePlayers[1].PlayerData.job.grade = None
        self.assertEqual(player.getJob().grade, 0)
        self.g.nativePlayers[1].PlayerData.job = None
        self.assertIsNone(player.getJob())

    def test_existing_wrapper_reads_replaced_qbx_player_data(self):
        provider = self.provider("server", "players", "qbox")
        player = provider.getPlayerFromId(provider, 1)
        self.run_lua("nativePlayers[1].PlayerData = {job={name='ambulance',grade={level=2},onduty=false}}")
        self.assertEqual((player.getJob().name, player.getJob().grade, player.getJob().onduty), ("ambulance", 2, False))
