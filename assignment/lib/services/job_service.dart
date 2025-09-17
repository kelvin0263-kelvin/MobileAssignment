import '../models/job.dart';

class JobService {
  // In-memory typed jobs
  static final List<Job> _jobs = _buildJobs();

  static List<Job> _buildJobs() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 9);
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1)); // Monday

    DateTime at(int dayOffset, int hour) => DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day + dayOffset,
          hour,
        );

    Job createJob({
      required String id,
      required String name,
      required String desc,
      required JobStatus status,
      required DateTime createdAt,
      required String customerName,
      required String plate,
      required String equipment,
    }) {
      return Job(
        id: id,
        jobName: name,
        description: desc,
        status: status,
        createdAt: createdAt,
        customer: Customer(
          name: customerName,
          contactNo: '+60123456789',
          address: 'Kuala Lumpur, Malaysia',
          plateNo: plate,
          equipment: equipment,
        ),
        requestedServices: [
          'Inspection',
          'General Service',
        ],
        assignedParts: [
          AssignedPart(name: 'Standard Part', quantity: 1, notes: 'Mock part'),
        ],
        notes: [],
      );
    }

    final List<Job> todayJobs = [
      createJob(
        id: 'JOB-T-001',
        name: 'Engine Oil Change',
        desc: 'Oil change and filter replacement',
        status: JobStatus.inProgress,
        createdAt: DateTime(today.year, today.month, today.day, 9),
        customerName: 'Ahmad bin Ismail',
        plate: 'WXY 1234',
        equipment: 'Toyota Camry 2020',
      ),
      createJob(
        id: 'JOB-T-002',
        name: 'Brake Inspection',
        desc: 'Brake pads check and fluid top up',
        status: JobStatus.onHold,
        createdAt: DateTime(today.year, today.month, today.day, 10),
        customerName: 'Sarah Tan',
        plate: 'ABC 5678',
        equipment: 'Honda Civic 2019',
      ),
      createJob(
        id: 'JOB-T-003',
        name: 'AC Service',
        desc: 'AC cleaning and refrigerant top-up',
        status: JobStatus.completed,
        createdAt: DateTime(today.year, today.month, today.day, 14),
        customerName: 'Raj Kumar',
        plate: 'DEF 9012',
        equipment: 'Proton Saga 2021',
      ),
      createJob(
        id: 'JOB-T-004',
        name: 'Tire Rotation',
        desc: 'Rotate and balance tires',
        status: JobStatus.inProgress,
        createdAt: DateTime(today.year, today.month, today.day, 16),
        customerName: 'Lim Wei Chen',
        plate: 'GHI 3456',
        equipment: 'Nissan Almera 2022',
      ),
    ];

    final List<Job> weekJobs = [
      createJob(
        id: 'JOB-W-005',
        name: 'Battery Replacement',
        desc: 'Replace 12V battery',
        status: JobStatus.onHold,
        createdAt: at(1, 11),
        customerName: 'John Lee',
        plate: 'JKL 7788',
        equipment: 'Perodua Myvi 2018',
      ),
      createJob(
        id: 'JOB-W-006',
        name: 'Suspension Check',
        desc: 'Front suspension noise diagnosis',
        status: JobStatus.completed,
        createdAt: at(2, 15),
        customerName: 'Aisha Noor',
        plate: 'MNO 3344',
        equipment: 'Mazda 3 2017',
      ),
      createJob(
        id: 'JOB-W-007',
        name: 'Transmission Fluid Change',
        desc: 'ATF drain and fill',
        status: JobStatus.inProgress,
        createdAt: at(3, 10),
        customerName: 'Kumaravel',
        plate: 'PQR 5566',
        equipment: 'Honda City 2016',
      ),
    ];

    return [...todayJobs, ...weekJobs];
  }

  Future<List<Job>> getJobs() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List<Job>.from(_jobs);
  }

  Future<Job?> getJobById(String jobId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    try {
      return _jobs.firstWhere((job) => job.id == jobId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateJobStatus(String jobId, JobStatus status) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return false;
    _jobs[index] = _jobs[index].copyWith(status: status);
    return true;
  }

  Future<bool> addJobNote(String jobId, String content, String? imagePath) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return false;
    final note = JobNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      createdAt: DateTime.now(),
      imagePath: imagePath,
    );
    final updatedNotes = [..._jobs[index].notes, note];
    _jobs[index] = _jobs[index].copyWith(notes: updatedNotes);
    return true;
  }

  Future<List<Job>> searchJobs(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (query.isEmpty) return getJobs();
    final q = query.toLowerCase();
    return _jobs.where((j) => j.jobName.toLowerCase().contains(q) || j.description.toLowerCase().contains(q)).toList();
  }
}
