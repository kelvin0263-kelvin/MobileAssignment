import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/job_service.dart';
import '../providers/job_provider.dart';
import '../utils/app_utils.dart';
import '../models/job.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();

  // Customer
  final _customerNameCtrl = TextEditingController();
  final _contactNoCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Vehicle
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _plateNoCtrl = TextEditingController();

  // Job
  final _jobNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _status = 'pending';
  String _priority = 'medium';
  final _assignedMechanicIdCtrl = TextEditingController();
  final _estimatedDurationCtrl = TextEditingController();
  DateTime? _deadline;

  // Assigned parts rows
  final List<_PartRow> _parts = [];
  List<PartOption> _partOptions = const <PartOption>[];
  bool _loadingParts = false;

  // Job tasks rows
  final List<_TaskRow> _tasks = [];
  List<ProcedureOption> _procedureOptions = const <ProcedureOption>[];
  bool _loadingProcedures = false;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadParts();
    _loadProcedures();
  }

  Future<void> _loadParts() async {
    setState(() => _loadingParts = true);
    try {
      final options = await JobService().getParts();
      if (!mounted) return;
      setState(() => _partOptions = options);
    } catch (_) {
      // ignore network errors; user can still type price and qty
    } finally {
      if (mounted) setState(() => _loadingParts = false);
    }
  }

  Future<void> _loadProcedures() async {
    setState(() => _loadingProcedures = true);
    try {
      final options = await JobService().getProcedures();
      if (!mounted) return;
      setState(() => _procedureOptions = options);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingProcedures = false);
    }
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _contactNoCtrl.dispose();
    _addressCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _plateNoCtrl.dispose();
    _jobNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _assignedMechanicIdCtrl.dispose();
    _estimatedDurationCtrl.dispose();
    for (final p in _parts) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    setState(() => _submitting = true);
    final service = JobService();
    try {
      // 1) Create customer
      final customerId = await service.createCustomer(
        name: _customerNameCtrl.text.trim(),
        contactNo: _contactNoCtrl.text.trim().isEmpty ? null : _contactNoCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      );

      // 2) Create vehicle
      final vehicleId = await service.createVehicle(
        customerId: customerId,
        brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
        year: int.tryParse(_yearCtrl.text.trim()),
        plateNo: _plateNoCtrl.text.trim().isEmpty ? null : _plateNoCtrl.text.trim(),
      );

      // 3) Create job
      final assignedMechanicId = int.tryParse(_assignedMechanicIdCtrl.text.trim());
      final estimatedMinutes = int.tryParse(_estimatedDurationCtrl.text.trim());
      final jobId = await service.createJob(
        jobName: _jobNameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        status: _status,
        priority: _priority,
        customerId: customerId,
        vehicleId: vehicleId,
        assignedMechanicId: assignedMechanicId,
        estimatedDuration: estimatedMinutes,
        deadline: _deadline,
      );

      // 4) Assigned parts (optional)
      final partsPayload = _parts
          .map((r) => r.toPayload())
          .where((p) => p != null)
          .map((p) => p!)
          .toList();
      if (partsPayload.isNotEmpty) {
        await service.createAssignedParts(jobId: jobId, parts: partsPayload);
      }

      // 5) Job tasks (optional)
      final tasksPayload = _tasks
          .map((t) => t.toInput())
          .where((t) => t != null)
          .map((t) => t!)
          .toList();
      if (tasksPayload.isNotEmpty) {
        await service.createJobTasks(jobId: jobId, tasks: tasksPayload);
      }

      if (!mounted) return;
      // refresh job list
      await Provider.of<JobProvider>(context, listen: false).loadJobs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job created')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Job'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Customer'),
              _LabeledField(
                label: 'Customer Name',
                child: TextFormField(
                  controller: _customerNameCtrl,
                  decoration: const InputDecoration(hintText: 'John Doe'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              _LabeledField(
                label: 'Contact No',
                child: TextFormField(
                  controller: _contactNoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '+1 555 1234'),
                ),
              ),
              _LabeledField(
                label: 'Address',
                child: TextFormField(
                  controller: _addressCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Street, City, State'),
                ),
              ),

              const SizedBox(height: 16),
              const _SectionTitle('Vehicle'),
              _LabeledField(
                label: 'Brand',
                child: TextFormField(
                  controller: _brandCtrl,
                  decoration: const InputDecoration(hintText: 'Toyota'),
                ),
              ),
              _LabeledField(
                label: 'Model',
                child: TextFormField(
                  controller: _modelCtrl,
                  decoration: const InputDecoration(hintText: 'Corolla'),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'Year',
                      child: TextFormField(
                        controller: _yearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '2020'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: 'Plate No',
                      child: TextFormField(
                        controller: _plateNoCtrl,
                        decoration: const InputDecoration(hintText: 'ABC1234'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const _SectionTitle('Job'),
              _LabeledField(
                label: 'Job Name',
                child: TextFormField(
                  controller: _jobNameCtrl,
                  decoration: const InputDecoration(hintText: 'Brake replacement'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              _LabeledField(
                label: 'Description',
                child: TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Describe the job...'),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'Status',
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('pending')),
                          DropdownMenuItem(value: 'accepted', child: Text('accepted')),
                          DropdownMenuItem(value: 'in_progress', child: Text('in_progress')),
                          DropdownMenuItem(value: 'on_hold', child: Text('on_hold')),
                          DropdownMenuItem(value: 'completed', child: Text('completed')),
                          DropdownMenuItem(value: 'declined', child: Text('declined')),
                        ],
                        onChanged: (v) => setState(() => _status = v ?? 'pending'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: 'Priority',
                      child: DropdownButtonFormField<String>(
                        value: _priority,
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('low')),
                          DropdownMenuItem(value: 'medium', child: Text('medium')),
                          DropdownMenuItem(value: 'high', child: Text('high')),
                          DropdownMenuItem(value: 'urgent', child: Text('urgent')),
                        ],
                        onChanged: (v) => setState(() => _priority = v ?? 'medium'),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'Assigned Mechanic ID (optional)',
                      child: TextFormField(
                        controller: _assignedMechanicIdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'e.g. 12'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: 'Estimated Duration (minutes)',
                      child: TextFormField(
                        controller: _estimatedDurationCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '90'),
                      ),
                    ),
                  ),
                ],
              ),
              _LabeledField(
                label: 'Deadline',
                child: InkWell(
                  onTap: _pickDeadline,
                  child: InputDecorator(
                    decoration: const InputDecoration(hintText: 'Select date/time'),
                    child: Text(
                      _deadline == null ? 'Not set' : _deadline!.toLocal().toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  const _SectionTitle('Assigned Parts'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _parts.add(_PartRow.empty()));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Part'),
                  )
                ],
              ),
              if (_parts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('No parts added'),
                ),
              if (_loadingParts)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              for (int i = 0; i < _parts.length; i++)
                _parts[i].build(context, partOptions: _partOptions, onRemove: () {
                  setState(() => _parts.removeAt(i));
                }),

              const SizedBox(height: 16),
              Row(
                children: [
                  const _SectionTitle('Job Tasks'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _tasks.add(_TaskRow.empty()));
                    },
                    icon: const Icon(Icons.add_task),
                    label: const Text('Add Task'),
                  ),
                ],
              ),
              if (_tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('No tasks added'),
                ),
              if (_loadingProcedures)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              for (int i = 0; i < _tasks.length; i++)
                _tasks[i].build(context, procedureOptions: _procedureOptions, onRemove: () {
                  setState(() => _tasks.removeAt(i));
                }),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitting ? null : _submit,
        icon: const Icon(Icons.save),
        label: const Text('Create Job'),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: AppTextStyles.headline2),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _PartRow {
  PartOption? selectedPart;
  final TextEditingController qtyCtrl;
  final TextEditingController unitPriceCtrl;
  String status;

  _PartRow({
    required this.selectedPart,
    required this.qtyCtrl,
    required this.unitPriceCtrl,
    required this.status,
  });

  factory _PartRow.empty() => _PartRow(
        selectedPart: null,
        qtyCtrl: TextEditingController(text: '1'),
        unitPriceCtrl: TextEditingController(),
        status: 'available',
      );

  void dispose() {
    qtyCtrl.dispose();
    unitPriceCtrl.dispose();
  }

  Map<String, dynamic>? toPayload() {
    if (selectedPart == null) return null;
    return {
      'name': selectedPart!.name,
      'part_id': selectedPart!.id,
      'quantity': int.tryParse(qtyCtrl.text.trim()) ?? 1,
      'unit_price': double.tryParse(unitPriceCtrl.text.trim()),
      'status': status,
    };
  }

  Widget build(BuildContext context, {required List<PartOption> partOptions, required VoidCallback onRemove}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<PartOption>(
                    value: selectedPart,
                    items: partOptions
                        .map((p) => DropdownMenuItem<PartOption>(
                              value: p,
                              child: Text(p.toString()),
                            ))
                        .toList(),
                    onChanged: (v) {
                      selectedPart = v;
                      // Auto-fill price if available
                      if (v?.unitPrice != null) {
                        unitPriceCtrl.text = v!.unitPrice!.toStringAsFixed(2);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Select Part'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: unitPriceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Unit Price'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: status,
                    items: const [
                      DropdownMenuItem(value: 'available', child: Text('available')),
                      DropdownMenuItem(value: 'requested', child: Text('requested')),
                      DropdownMenuItem(value: 'backordered', child: Text('backordered')),
                    ],
                    onChanged: (v) {
                      if (v != null) status = v;
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow {
  final TextEditingController descriptionCtrl;
  JobTaskStatus status;
  ProcedureOption? selectedProcedure;

  _TaskRow({
    required this.descriptionCtrl,
    required this.status,
    required this.selectedProcedure,
  });

  factory _TaskRow.empty() => _TaskRow(
        descriptionCtrl: TextEditingController(),
        status: JobTaskStatus.pending,
        selectedProcedure: null,
      );

  void dispose() {
    descriptionCtrl.dispose();
  }

  CreateTaskInput? toInput() {
    final desc = descriptionCtrl.text.trim();
    if (desc.isEmpty) return null;
    return CreateTaskInput(
      description: desc,
      status: status,
      procedureId: selectedProcedure?.id,
    );
  }

  Widget build(BuildContext context, {required List<ProcedureOption> procedureOptions, required VoidCallback onRemove}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextFormField(
              controller: descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Task Description'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<JobTaskStatus>(
                    value: status,
                    items: const [
                      DropdownMenuItem(value: JobTaskStatus.pending, child: Text('pending')),
                      DropdownMenuItem(value: JobTaskStatus.inProgress, child: Text('in_progress')),
                      DropdownMenuItem(value: JobTaskStatus.completed, child: Text('completed')),
                      DropdownMenuItem(value: JobTaskStatus.skipped, child: Text('skipped')),
                    ],
                    onChanged: (v) {
                      if (v != null) status = v;
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<ProcedureOption>(
                    value: selectedProcedure,
                    items: procedureOptions
                        .map((p) => DropdownMenuItem<ProcedureOption>(
                              value: p,
                              child: Text(p.toString()),
                            ))
                        .toList(),
                    onChanged: (v) {
                      selectedProcedure = v;
                    },
                    decoration: const InputDecoration(labelText: 'Procedure (optional)'),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


